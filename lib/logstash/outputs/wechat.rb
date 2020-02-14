# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# 当收到消息发送调用企业微信推送消息，可配置条件匹配发送 
class LogStash::Outputs::Wechat < LogStash::Outputs::Base

  config_name "wechat"

  # You can also use dynamic fields from the event with the `%{fieldname}` syntax.
  config :corp_id, :validate => :string, :required => true, :default => "wxid"

  config :corp_secret, :validate => :string, :required => true, :default => "corpsecret"
  config :to_user, :validate => :string, :default => "Owener"
  config :message_type, :validate => :string, :default => "text"
  config :agent_id, :validate => :number
  config :message_body, :validate => :string
  config :is_safe, :validate => :number, :default => 0
  config :debug, :validate => :boolean, :default => false

  public
  def register
    require "net/https"
    require "uri"
    require "json"

    options = {
      :corp_id               => @corp_id,
      :corp_secret           => @corp_secret,
      :debug                 => @debug
    }

    @logger.debug("Wechat Output Registered!")
  end # def register

  public
  def receive(event)
    
      @logger.debug? and @logger.debug("Creating wechat with these settings : ", :corp_id => @corp_id, :to_user => @to_user, :message_type => @message_type, :agent_id => @agent_id, :message_body => @message_body)

      corpid = event.sprintf(@corp_id)
      corpsecret = event.sprintf(@corp_secret)

      token_url = "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=#{corpid}&corpsecret=#{corpsecret}"
      token_uri = URI.parse(token_url)

      token_http = Net::HTTP.new(token_uri.host, token_uri.port)
      token_http.use_ssl = true
      token_http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      token_req = Net::HTTP::Get.new(token_uri.request_uri)

      token_ret = token_http.request(token_req)
      token_ret = JSON.parse(token_ret.body)
      qs_token = token_ret["access_token"]  # Get wechat token

      touser = event.sprintf(@to_user)
      msgtype = event.sprintf(@message_type)
      agentid = event.sprintf(@agent_id)
      content = event.sprintf(@message_body)
      safe = event.sprintf(@is_safe)

      payload = "{
        \"touser\": \"#{touser}\",
        \"msgtype\": \"#{msgtype}\",
        \"agentid\": \"#{agentid}\",
        \"text\": {
                 \"content\": \"#{content}\"
        },
        \"safe\": \"#{safe}\"
      }"

      msg_url = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=#{qs_token}"
      msg_uri = URI.parse(msg_url)

      msg_http = Net::HTTP.new(msg_uri.host, msg_uri.port)
      msg_http.use_ssl = true
      msg_http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      msg_req = Net::HTTP::Post.new(msg_uri.request_uri, initheader = {'Content-Type' =>'application/json'})
      msg_req.body = payload
      msg_ret = msg_http.request(msg_req)
      @logger.debug? and @logger.debug(:msg_ret => msg_ret.body)
      @logger.debug? and @logger.debug(:payload => payload)

  end # def receive
end # class LogStash::Outputs::Wechat