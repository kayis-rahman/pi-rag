#!/usr/bin/env python3
"""
SYNAPSE: Your Data Meets Intelligence

A local-first RAG (Retrieval-Augmented Generation) system with semantic, episodic and symbolic memory.
Your stored knowledge (neurons) fires into intelligent processing through synaptic transmission.
"""

from setuptools import setup, find_packages
import os
import sys

# Read version
version = "1.2.0"
if os.path.exists("VERSION"):
    with open("VERSION") as f:
        version = f.read().strip()

setup(
    name="synapse",
    version=version,
    description="Your Data Meets Intelligence. A local-first RAG system where your stored knowledge (neurons) fires into intelligent processing.",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    author="Kayis Rahman",
    author_email="kaisbk1@gmail.com",
    url="https://github.com/kayis-rahman/synapse",
    project_urls={
        "Bug Tracker": "https://github.com/kayis-rahman/synapse/issues",
        "Documentation": "https://github.com/kayis-rahman/synapse#readme",
        "Homepage": "https://synapse.dev",
        "Repository": "https://github.com/kayis-rahman/synapse",
    },
    license="MIT",
    packages=find_packages(exclude=["tests*", "examples*", "docs*"]),
    include_package_data=True,
    install_requires=[
        "llama-cpp-python>=0.2.0",
        "bge-m3>=0.0.1",
        "httpx>=0.24.0",
        "pydantic>=2.0.0",
        "python-dotenv>=1.0.0",
        "qdrant>=0.1.6",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "black>=23.0.0",
            "mypy>=1.0.0",
        ],
        "llama": [
            "transformers>=0.2.0",
            "sentencepiece>=0.1.9",
        ],
    },
    entry_points={
        "console_scripts": [
            "synapse-mcp-server=synapse.rag_server:main",
            "synapse-bulk-ingest=synapse.scripts.bulk_ingest:main",
            "synapse-system-status=synapse.scripts.rag_status:main",
            "synapse-start=synapse.scripts.start_server:main",
        ],
    },
    python_requires=">=3.8",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Tools :: CLI",
        "Programming Language :: Tools :: Build System",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
)
