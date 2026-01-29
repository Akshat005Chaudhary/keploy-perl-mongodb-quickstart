FROM perl:5.36

WORKDIR /app

# Install cpanm
RUN cpan App::cpanminus

# Copy project files
COPY . .

# Install Perl dependencies from cpanfile
RUN cpanm --notest --installdeps .

# Expose Mojolicious port
EXPOSE 5000

# Start the server
CMD ["perl", "app.pl", "daemon", "-l", "http://0.0.0.0:5000"]
