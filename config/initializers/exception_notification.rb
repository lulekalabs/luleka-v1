# Customize exception notification plugin

# email recipients
ExceptionNotification::Notifier.exception_recipients = %w(juergen@luleka.com)

# defaults to exception.notifier@default.com
ExceptionNotification::Notifier.sender_address = "\"Error | luleka.com\" <error@luleka.com>"

# defaults to "[ERROR] "
ExceptionNotification::Notifier.email_prefix = "[ERR] "