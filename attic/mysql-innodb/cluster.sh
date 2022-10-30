#!/usr/bin/mysqlsh --file

var dbPass = os.loadTextFile('/run/secrets/adminpass');

var dbConfig = dba.checkInstanceConfiguration('root@localhost',{password: dbPass});

if(dbConfig.status == "ok") {

  shell.connect('mysqlx://root@localhost:33060', dbPass);

  try {
    var cluster = dba.rebootClusterFromCompleteOutage()
  } catch {
    print("\n");
  }
  
} else if(dbConfig.status == "error") {
  
  print("Error in config status... configuring instance\n");
  dba.configureInstance("root@localhost", {password: dbPass, interactive: false});

  print("Rebooting...\n");
  dba.stopSandboxInstance(3306, {password: dbPass});

} else {

  print("Unknown config status!\n");
}

