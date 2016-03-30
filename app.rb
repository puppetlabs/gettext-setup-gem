require 'sinatra'
require_relative './lib/sinatra-i18n/gettext_setup'

class HelloWorldApp < Sinatra::Base
  include FastGettext::Translation

  before do
    FastGettext.locale = GettextSetup.negotiate_locale(env["HTTP_ACCEPT_LANGUAGE"])
  end

  get '/' do
    @messages =
      [
       _("Hello, world!"),
       # Translators need to know some details about the city here
       # So we explain it in a comment
       n_("There is %{count} bicycle in %{city}", "There are %{count} bicycles in %{city}") % {count: 1, city: "Beijing"},
       _("We negotiated a locale of %{locale}") % {locale: FastGettext.locale}]
    erb :index
  end

  get '/show' do
    "Negotiated locale: #{FastGettext.locale}\n"
  end
end
