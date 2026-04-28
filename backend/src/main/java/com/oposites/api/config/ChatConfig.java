package com.oposites.api.config;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Expone un bean de ChatClient construido desde el ChatClient.Builder que Spring AI autoconfigura.
 *
 * El builder está vinculado al proveedor configurado en application.yml (actualmente Gemini
 * vía endpoint OpenAI-compatible). Para cambiar de proveedor basta con cambiar el starter
 * en pom.xml y las properties en application.yml — ChatIAService no requiere modificaciones.
 */
@Configuration
public class ChatConfig {

    @Bean
    public ChatClient chatClient(ChatClient.Builder builder) {
        return builder.build();
    }
}
