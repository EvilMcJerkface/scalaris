% @copyright 2007-2014 Zuse Institute Berlin

%  Licensed under the Apache License, Version 2.0 (the "License");
%  you may not use this file except in compliance with the License.
%  You may obtain a copy of the License at
%
%      http://www.apache.org/licenses/LICENSE-2.0
%
%  Unless required by applicable law or agreed to in writing, software
%  distributed under the License is distributed on an "AS IS" BASIS,
%  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%  See the License for the specific language governing permissions and
%  limitations under the License.

%% @author Thorsten Schuett <schuett@zib.de>
%% @doc    Recover leases.
%% @end
%% @version $$
-module(lease_recover).
-author('schuett@zib.de').
-vsn('$Id$').

-include("scalaris.hrl").
-include("record_helpers.hrl").

-export([recover/1]).

-spec recover(list(prbr:state())) -> lease_list:lease_list().
recover(LeaseDBs) ->
    AllLeases = lists:append([prbr:tab2list(DB) || DB <- LeaseDBs]),
    Candidates = [L || {Id, L} <- AllLeases,
                       L =/= prbr_bottom, %% ??
                       Id =:= l_on_cseq:get_id(L), %% is first replica?
                       l_on_cseq:has_timed_out(L)],
    %% log:log("candidates ~p~n", [Candidates]),
    case Candidates of
        [] -> lease_list:empty();
        [Lease] -> % one potentially active lease: set active lease
            lease_list:make_lease_list(Lease, [], []);
        [_, _] -> % could be an ongoing split or an ongoing merge: finish operation
            io:format("~p~n", [Candidates]),
            ts = nyi, % ts: not yet implemented
            lease_list:empty()
    end.
