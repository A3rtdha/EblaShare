package ebla.core;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;

@JsonIgnoreProperties(ignoreUnknown = true)
@JsonAutoDetect(fieldVisibility = JsonAutoDetect.Visibility.ANY, getterVisibility = JsonAutoDetect.Visibility.NONE)
public class AppConfig {

    private static final ObjectMapper MAPPER = new ObjectMapper(new YAMLFactory())
        .registerModule(new JavaTimeModule());

    // Поля конфига с дефолтными значениями
    private String username = "Anonymous";
    private String syncFolder = Path.of(System.getProperty("user.home"), "EblaShare").toString();
    private int udpPort = 6969;
    private int tcpPort = 6970;

    // Загрузка конфига из файла
    public static AppConfig load(Path configPath) {
        AppConfig config;

        if (Files.exists(configPath)) {
            try {
                config = MAPPER.readValue(configPath.toFile(), AppConfig.class);
            } catch (IOException e) {
                throw new UncheckedIOException("Конфиг повреждён, исправь файл: " + configPath, e);
            }
        } else {
            config = new AppConfig();
            try {
                config.save(configPath);
            } catch (IOException e) {
                // TODO(CORE-3): заменить на slf4j после подключения logback
                System.err.println("Не удалось сохранить дефолтный конфиг: " + e.getMessage());
            }
        }

        return config;
    }

    // Парсинг и валидация порта из env-переменной
    private static int parsePort(String value, String envName, int fallback) {
        try {
            int port = Integer.parseInt(value);
            if (port < 1 || port > 65535) {
                System.err.println("Некорректное значение " + envName + " (вне диапазона 1–65535): " + value);
                return fallback;
            }
            return port;
        } catch (NumberFormatException e) {
            // TODO(CORE-3): заменить на slf4j после подключения logback
            System.err.println("Некорректное значение " + envName + ": " + value);
            return fallback;
        }
    }

    public void save(Path configPath) throws IOException {
        Files.createDirectories(configPath.getParent());
        MAPPER.writeValue(configPath.toFile(), this);
    }

    // Геттеры
    public String getUsername() {
        String envUser = System.getenv("EBLA_USERNAME");
        return envUser != null && !envUser.isBlank() ? envUser : this.username;
    }
    public String getSyncFolder() {
        String envFolder = System.getenv("EBLA_SYNC_FOLDER");
        return envFolder != null && !envFolder.isBlank() ? envFolder : this.syncFolder;
    }
    public int getUdpPort() {
        String envUdp = System.getenv("EBLA_UDP_PORT");
        return envUdp != null && !envUdp.isBlank() ? AppConfig.parsePort(envUdp, "EBLA_UDP_PORT", this.udpPort) : this.udpPort;
    }
    public int getTcpPort() {
        String envTcp = System.getenv("EBLA_TCP_PORT");
        return envTcp != null && !envTcp.isBlank() ? AppConfig.parsePort(envTcp, "EBLA_TCP_PORT", this.tcpPort) : this.tcpPort;
    }

    // Сеттеры
    public void setUsername(String username) { this.username = username; }
    public void setSyncFolder(String syncFolder) { this.syncFolder = syncFolder; }
    public void setUdpPort(int udpPort) { this.udpPort = udpPort; }
    public void setTcpPort(int tcpPort) { this.tcpPort = tcpPort; }
}
