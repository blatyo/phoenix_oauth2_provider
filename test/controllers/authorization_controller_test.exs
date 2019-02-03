defmodule PhoenixOauth2Provider.AuthorizationControllerTest do
  use PhoenixOauth2Provider.Test.ConnCase
  alias ExOauth2Provider.{OauthAccessGrants.OauthAccessGrant,
                          Scopes}
  alias PhoenixOauth2Provider.Test.Fixtures

  setup %{conn: conn} do
    user = Fixtures.user()
    conn = assign conn, :current_test_user, user
    {:ok, conn: conn, user: user}
  end

  test "new/2 renders authorization form", %{conn: conn, user: user} do
    application = Fixtures.application(%{user: user})

    conn = get conn, Routes.oauth_authorization_path(conn, :new, valid_request(application))
    body = html_response(conn, 200)

    assert body =~ "Authorize <strong>#{application.name}</strong> to use your account?"
    assert body =~ application.name
    application.scopes
    |> Scopes.to_list()
    |> Enum.each(fn(scope) ->
      assert body =~ "<li>#{scope}</li>"
    end)
  end

  test "new/2 renders error with invalid client", %{conn: conn} do
    conn = get conn, Routes.oauth_authorization_path(conn, :new, %{client_id: "", response_type: "code"})
    assert html_response(conn, 422) =~ "Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method."
  end

  test "new/2 redirects with error", %{conn: conn, user: user} do
    application = Fixtures.application(%{user: user})
    conn = get conn, Routes.oauth_authorization_path(conn, :new, %{client_id: application.uid, response_type: "other"})
    assert redirected_to(conn) == "https://example.com?error=unsupported_response_type&error_description=The+authorization+server+does+not+support+this+response+type."
  end

  test "new/2 with matching access token redirects when already shown", %{conn: conn, user: user} do
    application = Fixtures.application(%{user: user})
    Fixtures.access_token(%{user: user, application: application})

    conn = get conn, Routes.oauth_authorization_path(conn, :new, valid_request(application))
    assert redirected_to(conn) == "https://example.com?code=#{last_grant_token()}"
  end

  test "create/2 redirects", %{conn: conn, user: user} do
    application = Fixtures.application(%{user: user})
    conn = post conn, Routes.oauth_authorization_path(conn, :create, valid_request(application))
    assert redirected_to(conn) == "https://example.com?code=#{last_grant_token()}"

    assert last_grant().resource_owner_id == user.id
  end

  test "delete/2 redirects", %{conn: conn, user: user} do
    application = Fixtures.application(%{user: user})
    conn = delete conn, Routes.oauth_authorization_path(conn, :delete, valid_request(application))
    assert redirected_to(conn) == "https://example.com?error=access_denied&error_description=The+resource+owner+or+authorization+server+denied+the+request."
  end

  describe "application with native redirect uri" do
    setup %{conn: conn, user: user} do
      application = Fixtures.application(%{user: user, redirect_uri: "urn:ietf:wg:oauth:2.0:oob"})

      {:ok, conn: conn, user: user, application: application}
    end

    test "new/2 redirects to native", %{conn: conn, user: user, application: application} do
      Fixtures.access_token(%{user: user, application: application})

      conn = get conn, Routes.oauth_authorization_path(conn, :new, valid_request(application))
      assert redirected_to(conn) == Routes.oauth_authorization_path(conn, :show, last_grant_token())

      conn = get conn, Routes.oauth_authorization_path(conn, :show, last_grant_token())
      assert html_response(conn, 200) =~ last_grant_token()
    end

    test "create/2 shows json", %{conn: conn, application: application} do
      conn = post conn, Routes.oauth_authorization_path(conn, :create, valid_request(application))
      body = json_response(conn, 200)
      assert last_grant_token() == body["code"]
    end

    test "delete/2 shows json", %{conn: conn, application: application} do
      conn = delete conn, Routes.oauth_authorization_path(conn, :delete, valid_request(application))
      body = json_response(conn, 401)
      assert "The resource owner or authorization server denied the request." == body["error_description"]
    end
  end

  defp valid_request(%{uid: uid}), do: %{client_id: uid, response_type: "code"}

  defp last_grant do
    OauthAccessGrant
    |> ExOauth2Provider.repo().all()
    |> List.last()
  end

  defp last_grant_token, do: last_grant().token
end
