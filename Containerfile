FROM ghcr.io/nushell/nushell:latest-bookworm

# 基础镜像默认非 root，切回 root 执行系统操作
USER root

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

ARG DEV_UID=1000
ARG DEV_GID=1000

# 时区（纯本地操作，无需网络）
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 用户创建（纯本地操作）
RUN if getent group dev >/dev/null; then \
        groupmod -g "${DEV_GID}" dev; \
    elif getent group "${DEV_GID}" >/dev/null; then \
        groupmod -n dev "$(getent group "${DEV_GID}" | cut -d: -f1)"; \
    else \
        groupadd -g "${DEV_GID}" dev; \
    fi && \
    if getent passwd dev >/dev/null; then \
        usermod -u "${DEV_UID}" -g "${DEV_GID}" -d /home/dev -s /usr/bin/nu dev; \
        mkdir -p /home/dev; \
    elif getent passwd "${DEV_UID}" >/dev/null; then \
        usermod -l dev -d /home/dev -m -g "${DEV_GID}" -s /usr/bin/nu "$(getent passwd "${DEV_UID}" | cut -d: -f1)"; \
    else \
        useradd -m -u "${DEV_UID}" -g "${DEV_GID}" -s /usr/bin/nu dev; \
    fi && \
    echo "root:root" | chpasswd && \
    echo "dev:dev" | chpasswd && \
    echo "dev ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
