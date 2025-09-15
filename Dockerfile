FROM ruby:3.2.2

# Install system dependencies
RUN apt-get update -qq && apt-get install -y nodejs sqlite3

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile ./
RUN bundle install

# Copy the main application
COPY . .

# Make entrypoint script executable
RUN chmod +x /app/docker-entrypoint.sh

# Configure the main process to run when running the image
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"] 