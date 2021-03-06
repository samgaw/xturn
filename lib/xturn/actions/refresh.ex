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

defmodule Xirsys.XTurn.Actions.Refresh do
  @doc """
  Updates an allocations current expiry to its maximum set lifetime value
  """
  require Logger
  alias Xirsys.XTurn.Allocate.Store
  alias Xirsys.XTurn.Allocate.Client, as: AllocateClient
  alias Xirsys.XTurn.Tuple5
  alias Xirsys.Sockets.Conn
  alias XMediaLib.Stun

  def process(%Conn{decoded_message: %Stun{attrs: attrs}} = conn) do
    Logger.debug("refreshing #{inspect(conn.decoded_message)}")

    with true <- Map.has_key?(attrs, :lifetime),
         val <- Map.get(attrs, :lifetime),
         tuple5 <- Tuple5.to_map(Tuple5.create(conn, :_)) do
      do_refresh(conn, val, tuple5)
    else
      _ ->
        Logger.info("LIFETIME attribute not found during refresh request")
        Conn.response(conn, 400, "Bad Request")
    end
  end

  defp do_refresh(conn, <<0::32>>, tuple5) do
    case Store.lookup(tuple5) do
      {:ok, [client, {_relay_ip, _relay_port}, _, _]} ->
        Logger.debug("Refreshing with 0 time")
        AllocateClient.refresh(client, 0)

      {:error, :not_found} ->
        Conn.response(conn, 437, "Allocation Mismatch")
    end
  end

  defp do_refresh(conn, <<b::32>>, tuple5) when is_integer(b) do
    b = if b > 600, do: 600, else: b

    case Store.lookup(tuple5) do
      {:ok, [client, {_relay_ip, _relay_port}, _, _]} ->
        AllocateClient.refresh(client, b)
        new_attrs = %{lifetime: <<b::32>>}
        Conn.response(conn, :success, new_attrs)

      {:error, :not_found} ->
        Conn.response(conn, 437, "Allocation Mismatch")
    end
  end

  defp do_refresh(conn, val, _) do
    Logger.info("Bad value #{inspect(val)} in refresh request")
    Conn.response(conn, 400, "Bad Request")
  end
end
