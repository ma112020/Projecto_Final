import logging
import os
from pythonjsonlogger import jsonlogger


def setup_logging():
    """
    Configura o logging para usar o formato JSON para o Promtail/Loki.
    Versão final corrigida para evitar KeyErrors e erros de data.
    """

    # 1. Obter nível de log
    log_level_str = os.getenv("LOG_LEVEL", "INFO").upper()
    log_level = getattr(logging, log_level_str, logging.INFO)

    # 2. Configurar o root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)

    # 3. Formatter Customizado e Seguro
    class SafeJsonFormatter(jsonlogger.JsonFormatter):
        def add_fields(self, log_record, record, message_dict):
            super(SafeJsonFormatter, self).add_fields(log_record, record, message_dict)

            # Mapeamento para o formato esperado pelo Loki
            log_record["time"] = log_record.pop("asctime", None)
            log_record["level"] = log_record.pop("levelname", None)
            log_record["service.name"] = log_record.pop("name", None)

            # Injetar IDs de Telemetria se presentes (Instrumentação OTEL)
            if hasattr(record, "otelTraceID"):
                log_record["trace_id"] = record.otelTraceID
            if hasattr(record, "otelSpanID"):
                log_record["span_id"] = record.otelSpanID

    # Instanciar com formato de data ISO8601 correcto
    # Removemos o %f daqui pois o JsonFormatter lida com milissegundos internamente se configurado
    formatter = SafeJsonFormatter(
        fmt="%(asctime)s %(name)s %(levelname)s %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%SZ",
    )

    # 4. Configurar Handler
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)

    # Substituir handlers existentes para garantir unicidade
    root_logger.handlers = [handler]

    # Reconfigurar loggers do uvicorn para o nosso formato JSON
    logging.getLogger("uvicorn.error").handlers = [handler]
    logging.getLogger("uvicorn.access").handlers = [handler]

    # Silenciar bibliotecas ruidosas
    logging.getLogger("httpx").setLevel(logging.WARNING)

    print(f"Logging configurado em formato JSON no nível: {log_level_str}")


# Função chamada no arranque dos serviços
