{application,client,
             [{description,"Robot client controlling application"},
              {vsn,"1"},
              {registered,[]},
              {applications,[kernel,stdlib]},
              {mod,{client_app,[]}},
              {env,[{client_path,"../python-controller"},
                    {client_command,"python controller.py"}]},
              {modules,[client_app,client_controller,client_pb,client_sup]}]}.