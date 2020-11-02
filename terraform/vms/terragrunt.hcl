terraform {
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["/bin/bash","/home/kroy/Documents/infra/terraform/updatedns.sh"]
    run_on_error = true
  }
}
