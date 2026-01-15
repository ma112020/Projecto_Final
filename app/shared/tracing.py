import os
import logging
from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

logger = logging.getLogger(__name__)


def setup_tracing(app: FastAPI, service_name: str):
    """
    Configura o tracing distribuído via OpenTelemetry.
    Se o endpoint não estiver definido, o serviço opera sem exportação de traces.
    """
    endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")

    if not endpoint:
        # No Ubuntu local, este aviso será exibido, permitindo que a app corra normalmente
        logger.info(
            f"Tracing: OTEL_EXPORTER_OTLP_ENDPOINT não definido. Tracing desativado para {service_name}."
        )
        return

    # Define a identidade do serviço para o Grafana/Tempo
    resource = Resource.create({"service.name": service_name})

    # Inicializa o Tracer Provider
    provider = TracerProvider(resource=resource)

    try:
        # Configura o exportador gRPC para o coletor (Tempo)
        # insecure=True é vital para ambientes de desenvolvimento sem TLS
        exporter = OTLPSpanExporter(endpoint=endpoint, insecure=True)

        # BatchSpanProcessor agrupa os spans para melhor performance
        processor = BatchSpanProcessor(exporter)
        provider.add_span_processor(processor)

        # Define o provider como global
        trace.set_tracer_provider(provider)

        # Ativa a captura automática de todas as rotas FastAPI
        FastAPIInstrumentor.instrument_app(app)

        logger.info(f"✅ Tracing configurado: {service_name} enviando para {endpoint}")

    except Exception as e:
        # Se o coletor estiver offline, o serviço não morre
        logger.error(f"❌ Erro ao configurar OpenTelemetry: {e}")
