package com.oposites.api.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.ai.openai.api.OpenAiApi;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Cadena de fallback de proveedores IA.
 *
 * Orden: Groq (principal) → Cerebras (fallback 1) → Gemini Flash (fallback 2).
 * Los fallbacks se activan automáticamente si tienen API key configurada.
 * En cada llamada se intenta el primer proveedor; si falla por cualquier motivo
 * (429, timeout, 5xx) se prueba el siguiente.
 *
 * Variables de entorno opcionales:
 *   CEREBRAS_API_KEY  — activa Cerebras como fallback 1
 *   GEMINI_API_KEY    — activa Gemini Flash como fallback 2
 */
@Slf4j
@Component
public class AiProviderChain {

    private final List<ChatClient> chain = new ArrayList<>();

    public AiProviderChain(
            ChatClient.Builder groqBuilder,
            @Value("${app.ai.cerebras.api-key:}") String cerebrasApiKey,
            @Value("${app.ai.cerebras.model:llama-3.3-70b}") String cerebrasModel,
            @Value("${app.ai.gemini.api-key:}") String geminiApiKey,
            @Value("${app.ai.gemini.model:gemini-2.0-flash}") String geminiModel
    ) {
        // Proveedor 0: Groq (siempre activo, usa la autoconfiguration de Spring AI)
        chain.add(groqBuilder.build());
        log.info("AI chain: Groq activo (proveedor principal)");

        // Proveedor 1: Cerebras (OpenAI-compatible, free tier generoso)
        if (!cerebrasApiKey.isBlank()) {
            chain.add(buildOpenAiCompatibleClient(
                    "https://api.cerebras.ai/v1", cerebrasApiKey, cerebrasModel));
            log.info("AI chain: Cerebras activo como fallback 1 (modelo: {})", cerebrasModel);
        }

        // Proveedor 2: Gemini Flash (OpenAI-compatible endpoint de Google AI Studio)
        if (!geminiApiKey.isBlank()) {
            chain.add(buildOpenAiCompatibleClient(
                    "https://generativelanguage.googleapis.com/v1beta/openai", geminiApiKey, geminiModel));
            log.info("AI chain: Gemini activo como fallback 2 (modelo: {})", geminiModel);
        }

        log.info("AI chain inicializada con {} proveedor(es)", chain.size());
    }

    /**
     * Llama al LLM con fallback automático.
     * Itera los proveedores en orden hasta obtener una respuesta exitosa.
     *
     * @throws RuntimeException si todos los proveedores fallan
     */
    public String call(List<Message> messages) {
        Exception lastException = null;

        for (int i = 0; i < chain.size(); i++) {
            try {
                String content = chain.get(i)
                        .prompt()
                        .messages(messages)
                        .call()
                        .content();
                if (i > 0) {
                    log.info("AI chain: respuesta obtenida del proveedor fallback #{}", i);
                }
                return content;
            } catch (Exception e) {
                log.warn("AI chain: proveedor {} falló — {} — {}",
                        i, e.getClass().getSimpleName(), e.getMessage());
                lastException = e;
            }
        }

        throw new RuntimeException("Todos los proveedores IA fallaron. Último error: "
                + (lastException != null ? lastException.getMessage() : "desconocido"), lastException);
    }

    private ChatClient buildOpenAiCompatibleClient(String baseUrl, String apiKey, String model) {
        OpenAiApi api = OpenAiApi.builder()
                .baseUrl(baseUrl)
                .apiKey(apiKey)
                .build();

        OpenAiChatModel chatModel = OpenAiChatModel.builder()
                .openAiApi(api)
                .defaultOptions(OpenAiChatOptions.builder()
                        .model(model)
                        .temperature(0.7)
                        .build())
                .build();

        return ChatClient.builder(chatModel).build();
    }
}
