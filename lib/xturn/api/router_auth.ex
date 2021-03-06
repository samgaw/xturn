### ----------------------------------------------------------------------
###
### Copyright (c) 2013 - 2018 Lee Sylvester and Xirsys LLC <experts@xirsys.com>
###
### All rights reserved.
###
### XTurn is licensed by Xirsys under the Apache
### License, Version 2.0. (the "License");
###
### you may not use this file except in compliance with the License.
### You may obtain a copy of the License at
###
###      http://www.apache.org/licenses/LICENSE-2.0
###
### Unless required by applicable law or agreed to in writing, software
### distributed under the License is distributed on an "AS IS" BASIS,
### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
### See the License for the specific language governing permissions and
### limitations under the License.
###
### See LICENSE for the full license text.
###
### ----------------------------------------------------------------------

defmodule Xirsys.API.Router.Auth do
  use Maru.Router

  namespace :auth do
    desc("Adds a user to the user list")

    params do
      optional(:username, type: String)
      optional(:password, type: String)
      # This is used for analytics purposes. Maybe a room name or project name
      optional(:namespace, type: String)
      # id of the account creating the user. Useful for analytics and billing
      optional(:peer_id, type: String)
    end

    post do
      if not params[:username] or not params[:password] do
        {:ok, u, p} =
          Xirsys.XTurn.Auth.Client.create_user(
            params[:namespace] || "",
            params[:peer_id] || ""
          )

        json(conn, %{status: :ok, username: u, password: p})
      else
        {:ok, u, p} =
          Xirsys.XTurn.Auth.Client.add_user(
            params[:username],
            params[:password],
            params[:namespace] || "",
            params[:peer_id] || ""
          )

        json(conn, %{status: :ok, username: u, password: p})
      end
    end
  end
end
