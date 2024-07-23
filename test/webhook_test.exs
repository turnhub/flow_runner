defmodule Turn.Build.Blocks.WebhookTest do
  use ExUnit.Case, async: true
  import FlowRunner.Test.Utils
  alias FlowRunner.CustomBlocks.Webhook

  setup :with_flow_loader!

  def find_blocks(blocks, names) when is_list(names),
    do: Enum.flat_map(names, &find_blocks(blocks, &1))

  def find_blocks(blocks, name), do: Enum.filter(blocks, &(&1.name == name))

  @tag flow:
         {"test/simulator/webhook_getting_an_internal_server_error.flow", ["https://example.org"]}
  test "webhook getting an Internal Server Error",
       %{container: container, container_bypasses: [{"https://example.org", bypass}]} = _ctx do
    bypass_url = "http://127.0.0.1:#{bypass.port}/webhook"

    assert [flow] = container.flows
    assert [webhook_block] = find_blocks(flow.blocks, ["resp"])
    assert webhook_block.type == "Io.Turn.Webhook"

    Bypass.expect_once(bypass, "POST", "/webhook", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.resp(502, "Internal Server Error")
    end)

    assert webhook_block.config == %{
             body: "hello world!",
             cache_ttl: 60_000,
             headers: [
               ["content-type", "application/json"],
               ["accept", "application/json"]
             ],
             method: "POST",
             mode: "sync",
             query: [["foo", "bar"]],
             timeout: 500,
             url: bypass_url
           }

    assert {:ok, _container, _flow, _block, context} =
             Webhook.evaluate_incoming(container, flow, webhook_block, %FlowRunner.Context{})

    assert context.vars["resp"] ==
             %{
               "body" => "hello world!",
               "headers" => [["content-type", "application/json"], ["accept", "application/json"]],
               "mode" => "sync",
               "query" => [["foo", "bar"]],
               "status" => 500,
               "url" => bypass_url
             }
  end

  @tag flow: {"test/simulator/webhook_returning_invalid_json.flow", ["https://example.org"]}
  test "webhook returning invalid JSON", %{
    container: container,
    container_bypasses: [{_, bypass}]
  } do
    bypass_url = "http://127.0.0.1:#{bypass.port}/webhook/"

    assert [flow] = container.flows

    assert [webhook_block] = find_blocks(flow.blocks, ["resp"])

    assert webhook_block.type == "Io.Turn.Webhook"

    # Simulate webhook returning the string "OK" instead of JSON
    Bypass.expect_once(bypass, "POST", "/webhook", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.resp(200, "OK")
    end)

    assert {:ok, _container, _flow, _block, context} =
             Webhook.evaluate_incoming(container, flow, webhook_block, %FlowRunner.Context{})

    assert context.vars["resp"] ==
             %{
               "body" => "OK",
               "headers" => [["content-type", "application/json"], ["accept", "application/json"]],
               "mode" => "sync",
               "query" => [["foo", "bar"]],
               "status" => 200,
               "url" => bypass_url
             }
  end

  @tag flow: {"test/simulator/webhook_hitting_a_timeout.flow", ["https://example.org"]}
  test "webhook hitting a timeout", %{container: container, container_bypasses: [{_, bypass}]} do
    bypass_url = "http://127.0.0.1:#{bypass.port}/timeout"

    Bypass.expect(bypass, "POST", "/timeout", fn conn ->
      Process.sleep(100)

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{}))
    end)

    assert [flow] = container.flows

    assert [webhook_block] = find_blocks(flow.blocks, ["resp"])

    assert webhook_block.type == "Io.Turn.Webhook"

    assert webhook_block.config == %{
             body: "hello world!",
             cache_ttl: 60_000,
             headers: [["content-type", "text/plain; charset=utf-8"]],
             method: "POST",
             mode: "sync",
             query: [["foo", "bar"]],
             timeout: 100,
             url: bypass_url
           }

    assert {:ok, _container, _flow, _block, context} =
             Webhook.evaluate_incoming(container, flow, webhook_block, %FlowRunner.Context{})

    assert context.vars["resp"] ==
             %{
               "body" => "ERROR: timeout",
               "headers" => %{
                 "content-type" => ["text/plain; charset=utf-8"]
               },
               "mode" => "sync",
               "query" => %{"foo" => ["bar"]},
               "status" => nil,
               "url" => bypass_url
             }

    Bypass.pass(bypass)
  end
end
