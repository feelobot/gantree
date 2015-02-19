require 'slackr'
class Notification

  def initialize(options={})
    @slack = Slackr.connect(options["team"], options["token"])
  end

  def say(msg)
    @slack.say(msg)
  end
end

