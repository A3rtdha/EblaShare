package ebla.core;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Узел сети: идентичность, адрес, время последнего контакта и произвольные метрики (CPU, RAM и т.д.).
 */
public record Peer(
        @JsonProperty("id") UUID id,
        @JsonProperty("name") String name,
        @JsonProperty("ip") String ip,
        @JsonProperty("lastSeen") Instant lastSeen,
        @JsonProperty("metrics") Map<String, Object> metrics
) {
    public Peer {
        metrics = metrics == null ? Map.of() : Map.copyOf(metrics);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        Peer peer = (Peer) o;
        return Objects.equals(id, peer.id);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(id);
    }
}
