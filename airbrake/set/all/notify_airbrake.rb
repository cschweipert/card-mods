event :notify_airbrake, :after=>:notable_exception_raised do
  Env[:controller].send :notify_airbrake, Card::Error.current if Airbrake.configuration.api_key
end
