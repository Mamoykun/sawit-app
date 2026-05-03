package com.sawitku.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

/**
 * Serves uploaded lahan photos as static resources.
 * Photos are saved to {upload.dir}/photos/{lahanId}/{uuid}.jpg
 * and accessible at /photos/{lahanId}/{uuid}.jpg.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${upload.dir:uploads}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String absPath = Paths.get(uploadDir).toAbsolutePath().normalize().toString();
        registry.addResourceHandler("/photos/**")
                .addResourceLocations("file:" + absPath + "/photos/");
    }
}
