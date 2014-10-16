require 'slackr'
class Notification

  def initialize(options={})
    @slack = Slackr.connect(options["team"], options["token"], {
      "channel" => options["channel"], 
      "username" => options["username"], 
      "icon_url" => options["icon_url"]
    })
  end

  def say(msg)
    @slack.say(msg)
  end

end