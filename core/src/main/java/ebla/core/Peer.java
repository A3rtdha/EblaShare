package ebla;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.Objects;
import java.util.UUID;

@JsonIgnoreProperties(ignoreUnknown = true)
public class Peer {

    @JsonProperty("id")
    private UUID id;

    @JsonProperty("name")
    private String name;

    @JsonProperty("ip")
    private String ip;

    private long lastSeen;

    private Object metrics; // fill it out in MON-1

    public Peer(UUID id, String name, String ip) {
        this.id = id;
        this.name = name;
        this.ip = ip;
        this.lastSeen = System.currentTimeMillis();
    }

    // Getters
    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getIp() { return ip; }
    public long getLastSeen() { return lastSeen; }
    public Object getMetrics() { return metrics; } // change it after implementing the metrics

    // Setters
    public void setLastSeen(long lastSeen) { this.lastSeen = lastSeen; }
    public void setMetrics(Object metrics) { this.metrics = metrics; } // change it after implementing the metrics

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