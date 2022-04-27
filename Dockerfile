FROM httpd:2.4
COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
RUN mkdir /usr/local/apache2/var \
    && chmod 777 /usr/local/apache2/var \
    && mkdir /usr/local/apache2/htdocs/charts \
    && chmod 777 /usr/local/apache2/htdocs/charts
    
