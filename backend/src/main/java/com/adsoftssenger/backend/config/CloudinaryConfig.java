package com.adsoftssenger.backend.config;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

@Configuration
public class CloudinaryConfig {

    @Bean
    public CloudinaryCredentials cloudinaryCredentials(
            @Value("${CLOUDINARY_CLOUD_NAME:}") String cloudName,
            @Value("${CLOUDINARY_API_KEY:}") String apiKey,
            @Value("${CLOUDINARY_API_SECRET:}") String apiSecret
    ) {
        return new CloudinaryCredentials(cloudName, apiKey, apiSecret);
    }

    @Bean
    public Cloudinary cloudinary(CloudinaryCredentials credentials) {
        return new Cloudinary(ObjectUtils.asMap(
                "cloud_name", credentials.cloudName(),
                "api_key", credentials.apiKey(),
                "api_secret", credentials.apiSecret(),
                "secure", true
        ));
    }

    public record CloudinaryCredentials(String cloudName, String apiKey, String apiSecret) {

        public boolean isComplete() {
            return StringUtils.hasText(cloudName)
                    && StringUtils.hasText(apiKey)
                    && StringUtils.hasText(apiSecret);
        }
    }
}
