package ebla.sync.transfer;

/**
 * Константы протокола TCP-передачи файлов Ebla.
 * Endianness: Big Endian (Network byte order).
 */
public final class TransferConstants {

    // Версия протокола. Если формат заголовка меняется несовместимо — увеличиваем.
    public static final int PROTOCOL_VERSION = 1;

    // Максимальный размер одного чанка данных (512 KB).
    // Предотвращает OOM: буферы чтения/записи выделяются строго до этого размера.
    public static final int MAX_CHUNK_SIZE = 512 * 1024;

    // Максимальный размер JSON заголовка (1 MB). Защита от OOM при повреждении потока.
    public static final int MAX_HEADER_SIZE = 1024 * 1024;

    private TransferConstants() {}
}
