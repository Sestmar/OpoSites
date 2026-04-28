package com.oposites.api;

import com.oposites.api.security.JwtProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(JwtProperties.class)
public class OpositesApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(OpositesApiApplication.class, args);
    }
}
