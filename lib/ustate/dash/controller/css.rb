class UState::Dash
  get '/css' do
    scss :css, :layout => false
  end
end
