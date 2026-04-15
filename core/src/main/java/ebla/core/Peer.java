package ebla.core;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.Objects;
import java.util.UUID;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class Peer {

    private UUID id;
    private String name;
    private String ip;
    private long lastSeen;
    private Map<String, Object> metrics;

    @JsonCreator
    public Peer(
        @JsonProperty("id") UUID id,
        @JsonProperty("name") String name,
        @JsonProperty("ip") String ip) {
        this.id = id;
        this.name = name;
        this.ip = ip;
    }

    // Getters
    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getIp() { return ip; }
    public long getLastSeen() { return lastSeen; }
    public Map<String, Object> getMetrics() { return metrics; }

    // Setters
    public void setLastSeen(long lastSeen) { this.lastSeen = lastSeen; }
    public void setMetrics(Map<String, Object> metrics) { this.metrics = metrics; }

    // equals и hashCode only on id
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Peer peer)) return false;
        return Objects.equals(id, peer.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "Peer{id=" + id + ", name='" + name + "', ip='" + ip + "'}";
    }
}
