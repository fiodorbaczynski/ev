Mox.defmock(RepoMock, for: Ecto.Repo)
Mox.defmock(PublisherMock, for: EV.Publisher)
Mox.defmock(ApplicatorMock, for: EV.Publisher)
Mox.defmock(HandlerMock, for: EV.Handler)

ExUnit.start()
