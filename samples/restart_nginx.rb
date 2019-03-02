Runbook.book "Restart Nginx" do
  description <<-DESC
This is a simple runbook to restart nginx and verify
it starts successfully
  DESC

  section "Restart Nginx" do
    server "app01.prod"

    step "Stop Nginx" do
      note "Stopping Nginx..."
      command "service nginx stop"
      assert %q{service nginx status | grep "not running"}
    end

    step { wait 5 }

    step "Start Nginx" do
      note "Starting Nginx..."
      command "service nginx start"
      assert %q{service nginx status | grep "is running"}
      confirm "Nginx is taking traffic?"
      notice "Make sure to report why you restarted nginx"
    end
  end
end
