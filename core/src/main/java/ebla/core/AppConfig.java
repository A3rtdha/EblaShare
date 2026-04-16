package ebla.core;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@JsonIgnoreProperties(ignoreUnknown = true)
public class AppConfig {

    private static final ObjectMapper MAPPER = new ObjectMapper(new YAMLFactory());

    private static final Path CONFIG_PATH =
        Path.of(System.getProperty("user.home"), ".eblashare", "config.yml");

    // Поля конфига с дефолтными значениями
    private String username = "Anonymous";
    private String syncFolder = Path.of(System.getProperty("user.home"), "EblaShare").toString();
    private int udpPort = 6969;
    private int tcpPort = 6970;

    private AppConfig() {}

    // Singleton
    private static class Holder {
        static final AppConfig INSTANCE = load();
    }
    public static AppConfig getInstance() {
        return Holder.INSTANCE;
    }

    // Загрузка конфига из файла + env overrides
    private static AppConfig load() {
        AppConfig config;

        if (Files.exists(CONFIG_PATH)) {
            try {
                config = MAPPER.readValue(CONFIG_PATH.toFile(), AppConfig.class);
            } catch (IOException e) {
                // TODO(CORE-3): заменить на slf4j после подключения logback
                System.err.println("Не удалось прочитать конфиг, используем дефолтный: " + e.getMessage());
                config = new AppConfig();
            }
        } else {
            config = new AppConfig();
            try {
                config.save();
            } catch (IOException e) {
                System.err.println("Не удалось сохранить дефолтный конфиг: " + e.getMessage());
            }
        }

        return applyEnvOverrides(config);
    }

    // Переопределение полей через переменные окружения (для Docker/runtime).
    // Внимание: если после этого вызвать save(), env-значения запишутся в файл.
    private static AppConfig applyEnvOverrides(AppConfig config) {
        String envUser = System.getenv("EBLA_USERNAME");
        if (envUser != null && !envUser.isBlank()) config.setUsername(envUser);

        String envFolder = System.getenv("EBLA_SYNC_FOLDER");
        if (envFolder != null && !envFolder.isBlank()) config.setSyncFolder(envFolder);

        String envUdp = System.getenv("EBLA_UDP_PORT");
        if (envUdp != null) config.setUdpPort(parsePort(envUdp, "EBLA_UDP_PORT", config.getUdpPort()));

        String envTcp = System.getenv("EBLA_TCP_PORT");
        if (envTcp != null) config.setTcpPort(parsePort(envTcp, "EBLA_TCP_PORT", config.getTcpPort()));

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
            System.err.println("Некорректное значение " + envName + ": " + value);
            return fallback;
        }
    }

    /**
     * Сохраняет текущее состояние конфига на диск.
     * Внимание: если были применены env-оверрайды, они тоже запишутся в файл.
     */
    public void save() throws IOException {
        Files.createDirectories(CONFIG_PATH.getParent());
        MAPPER.writeValue(CONFIG_PATH.toFile(), this);
    }

    // Геттеры
    public String getUsername() { return username; }
    public String getSyncFolder() { return syncFolder; }
    public int getUdpPort() { return udpPort; }
    public int getTcpPort() { return tcpPort; }

    // Сеттеры
    public void setUsername(String username) { this.username = username; }
    public void setSyncFolder(String syncFolder) { this.syncFolder = syncFolder; }
    public void setUdpPort(int udpPort) { this.udpPort = udpPort; }
    public void setTcpPort(int tcpPort) { this.tcpPort = tcpPort; }
}
