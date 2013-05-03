-module(aggrsense_appmod).

-export([out/1]).

-include_lib("yaws/include/yaws_api.hrl").

-define(REQUIRE_GET(Met, Body),
        case (Met) of
            'GET' -> Body;
            _     -> [{status, 405}]
        end).
-define(REQUIRE_POST(Met, Body),
        case (Met) of
            'POST'-> Body;
            _     -> [{status, 405}]
        end).

-define(PARSE_JSON(A, Spec, Var, Body),
        case aggrsense_util:parse_and_validate_json(yaws_api:arg_clidata(A), Spec) of
            {ok, Var} ->
                (Body);
            {error, XXErrorText} ->
                [{status, 400},
                 {content, "text/plain", [XXErrorText, "\n"]}]
        end).

out(A) ->
    Method = yaws_api:http_request_method(yaws_api:arg_req(A)),
    Uri = yaws_api:request_url(A),
    Path = string:tokens(Uri#url.path, "/"),
    dispatch(Method, Path, A).

%% General pages:
dispatch(Met, ["aggrsense"], A) ->
    ?REQUIRE_GET(Met, base_page(A));
dispatch(Met, ["aggrsense", "test"|_], A) ->
    ?REQUIRE_GET(Met, test_page(A));
dispatch(Met, ["aggrsense", "aqe_area"|_], A) ->
    ?REQUIRE_POST(Met,
                  ?PARSE_JSON(A, {object, [{<<"x1">>, number},
                                           {<<"y1">>, number},
                                           {<<"x2">>, number},
                                           {<<"y2">>, number},
                                           {<<"destResource">>, string}
                                          ]},
                              {X1,Y1,X2,Y2,DestResource},
                              aqe_area_page(X1,Y1,X2,Y2,DestResource)));
dispatch(_, _, _) ->
    [{status, 404}].

base_page(_A) ->
    {ehtml,
     [{h1, [], "This is GateSenseAggr."},
      {p, [], "The REST interface is up and running."}
     ]}.

test_page(A) ->
    Uri = yaws_api:request_url(A),
    Path = string:tokens(Uri#url.path, "/"),
    Method = yaws_api:http_request_method(yaws_api:arg_req(A)),
    {ehtml,
     [{p, [], "Hello, World!"},
      {dl, [], [
      {dt, [], "Method:"}, {dd,[], io_lib:format("~p", [Method])},
      {dt, [], "Uri:"}, {dd,[], io_lib:format("~p", [Uri])},
      {dt, [], "Path:"}, {dd,[], io_lib:format("~p", [Path])}
               ]},
      {p, [], io_lib:format("~p", [A])}
     ]}.

aqe_area_page(X1,Y1,X2,Y2,DestResource) ->
    {ok, Result} = aggrsense_storage:query_rect(X1,Y1,X2,Y2),
    JsonResult = [ {[{<<"sensor">>, Name},
                     {<<"time">>, 0},
                     {<<"value">>, Sum/Count}]}
                  || {Name, {summary, _Min,_Max,Count,Sum}} <- Result],
    {ok,UploadResult} = aggrsense_ckan:create_resource(DestResource, JsonResult),
    error_logger:info_msg("Upload: ~p\n", [UploadResult]),
    {ehtml,
     [{p, [], "AQE Area Query"},
      {dl, [], [
      {dt, [], "X1:"}, {dd,[], io_lib:format("~f", [float(X1)])},
      {dt, [], "Y1:"}, {dd,[], io_lib:format("~f", [float(Y1)])},
      {dt, [], "X2:"}, {dd,[], io_lib:format("~f", [float(X2)])},
      {dt, [], "Y2:"}, {dd,[], io_lib:format("~f", [float(Y2)])},
      {dt, [], "Destination Resource:"}, {dd,[], io_lib:format("~s", [DestResource])},
      {dt, [], "Result:"}, {dd,[], io_lib:format("~p", [Result])},
      {dt, [], "JSON Result:"}, {dd,[], io_lib:format("~p", [JsonResult])}
               ]}
     ]}.
