ServerCtrl::Application.routes.draw do
  root "server_control#index"

  get 'processes' => "server_control#processes"
  get 'processes/:id' => "server_control#processes"

  get 'login' => "server_control#login"
  post 'login' => "server_control#login"

  get 'logout' => "server_control#logout"


  get 'web' => "server_control#web"

  get 'setup' => "server_control#setup"
  post 'setup' => "server_control#setup"
end
