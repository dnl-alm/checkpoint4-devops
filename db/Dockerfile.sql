FROM gvenzl/oracle-xe:21-slim

EXPOSE 1521

COPY init/init.sql /container-entrypoint-initdb.d/init.sql