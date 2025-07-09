Mox.defmock(Tesla.MockAdapter, for: Tesla.Adapter)
Application.put_env(:tesla, :adapter, Tesla.MockAdapter)

ExUnit.start()
