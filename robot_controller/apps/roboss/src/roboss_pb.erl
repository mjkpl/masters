-file("src/roboss_pb.erl", 1).

-module(roboss_pb).

-export([encode_ack/1, decode_ack/1,
	 delimited_decode_ack/1, encode_robotslist/1,
	 decode_robotslist/1, delimited_decode_robotslist/1,
	 encode_wheelscommand/1, decode_wheelscommand/1,
	 delimited_decode_wheelscommand/1,
	 encode_robossrequest/1, decode_robossrequest/1,
	 delimited_decode_robossrequest/1, encode_robotstate/1,
	 decode_robotstate/1, delimited_decode_robotstate/1]).

-export([has_extension/2, extension_size/1,
	 get_extension/2, set_extension/3]).

-export([decode_extensions/1]).

-export([encode/1, decode/2, delimited_decode/2]).

-record(ack, {}).

-record(robotslist, {robotnames}).

-record(wheelscommand,
	{frontleft, frontright, rearleft, rearright}).

-record(robossrequest, {type, wheelscmd}).

-record(robotstate, {x, y, theta, timestamp}).

encode([]) -> [];
encode(Records) when is_list(Records) ->
    delimited_encode(Records);
encode(Record) -> encode(element(1, Record), Record).

encode_ack(Records) when is_list(Records) ->
    delimited_encode(Records);
encode_ack(Record) when is_record(Record, ack) ->
    encode(ack, Record).

encode_robotslist(Records) when is_list(Records) ->
    delimited_encode(Records);
encode_robotslist(Record)
    when is_record(Record, robotslist) ->
    encode(robotslist, Record).

encode_wheelscommand(Records) when is_list(Records) ->
    delimited_encode(Records);
encode_wheelscommand(Record)
    when is_record(Record, wheelscommand) ->
    encode(wheelscommand, Record).

encode_robossrequest(Records) when is_list(Records) ->
    delimited_encode(Records);
encode_robossrequest(Record)
    when is_record(Record, robossrequest) ->
    encode(robossrequest, Record).

encode_robotstate(Records) when is_list(Records) ->
    delimited_encode(Records);
encode_robotstate(Record)
    when is_record(Record, robotstate) ->
    encode(robotstate, Record).

encode(robotstate, Records) when is_list(Records) ->
    delimited_encode(Records);
encode(robotstate, Record) ->
    [iolist(robotstate, Record)
     | encode_extensions(Record)];
encode(robossrequest, Records) when is_list(Records) ->
    delimited_encode(Records);
encode(robossrequest, Record) ->
    [iolist(robossrequest, Record)
     | encode_extensions(Record)];
encode(wheelscommand, Records) when is_list(Records) ->
    delimited_encode(Records);
encode(wheelscommand, Record) ->
    [iolist(wheelscommand, Record)
     | encode_extensions(Record)];
encode(robotslist, Records) when is_list(Records) ->
    delimited_encode(Records);
encode(robotslist, Record) ->
    [iolist(robotslist, Record)
     | encode_extensions(Record)];
encode(ack, Records) when is_list(Records) ->
    delimited_encode(Records);
encode(ack, Record) ->
    [iolist(ack, Record) | encode_extensions(Record)].

encode_extensions(_) -> [].

delimited_encode(Records) ->
    lists:map(fun (Record) ->
		      IoRec = encode(Record),
		      Size = iolist_size(IoRec),
		      [protobuffs:encode_varint(Size), IoRec]
	      end,
	      Records).

iolist(robotstate, Record) ->
    [pack(1, required,
	  with_default(Record#robotstate.x, none), double, []),
     pack(2, required,
	  with_default(Record#robotstate.y, none), double, []),
     pack(3, required,
	  with_default(Record#robotstate.theta, none), double,
	  []),
     pack(4, required,
	  with_default(Record#robotstate.timestamp, none), int64,
	  [])];
iolist(robossrequest, Record) ->
    [pack(1, required,
	  with_default(Record#robossrequest.type, none),
	  robossrequest_type, []),
     pack(2, optional,
	  with_default(Record#robossrequest.wheelscmd, none),
	  wheelscommand, [])];
iolist(wheelscommand, Record) ->
    [pack(1, required,
	  with_default(Record#wheelscommand.frontleft, none),
	  double, []),
     pack(2, required,
	  with_default(Record#wheelscommand.frontright, none),
	  double, []),
     pack(3, required,
	  with_default(Record#wheelscommand.rearleft, none),
	  double, []),
     pack(4, required,
	  with_default(Record#wheelscommand.rearright, none),
	  double, [])];
iolist(robotslist, Record) ->
    [pack(1, repeated,
	  with_default(Record#robotslist.robotnames, none),
	  string, [])];
iolist(ack, _Record) -> [].

with_default(Default, Default) -> undefined;
with_default(Val, _) -> Val.

pack(_, optional, undefined, _, _) -> [];
pack(_, repeated, undefined, _, _) -> [];
pack(_, repeated_packed, undefined, _, _) -> [];
pack(_, repeated_packed, [], _, _) -> [];
pack(FNum, required, undefined, Type, _) ->
    exit({error,
	  {required_field_is_undefined, FNum, Type}});
pack(_, repeated, [], _, Acc) -> lists:reverse(Acc);
pack(FNum, repeated, [Head | Tail], Type, Acc) ->
    pack(FNum, repeated, Tail, Type,
	 [pack(FNum, optional, Head, Type, []) | Acc]);
pack(FNum, repeated_packed, Data, Type, _) ->
    protobuffs:encode_packed(FNum, Data, Type);
pack(FNum, _, Data, _, _) when is_tuple(Data) ->
    [RecName | _] = tuple_to_list(Data),
    protobuffs:encode(FNum, encode(RecName, Data), bytes);
pack(FNum, _, Data, Type, _)
    when Type =:= bool;
	 Type =:= int32;
	 Type =:= uint32;
	 Type =:= int64;
	 Type =:= uint64;
	 Type =:= sint32;
	 Type =:= sint64;
	 Type =:= fixed32;
	 Type =:= sfixed32;
	 Type =:= fixed64;
	 Type =:= sfixed64;
	 Type =:= string;
	 Type =:= bytes;
	 Type =:= float;
	 Type =:= double ->
    protobuffs:encode(FNum, Data, Type);
pack(FNum, _, Data, Type, _) when is_atom(Data) ->
    protobuffs:encode(FNum, enum_to_int(Type, Data), enum).

enum_to_int(robossrequest_type, 'RESET') -> 5;
enum_to_int(robossrequest_type, 'STOP') -> 4;
enum_to_int(robossrequest_type, 'START') -> 3;
enum_to_int(robossrequest_type, 'STATE_REQUEST') -> 2;
enum_to_int(robossrequest_type,
	    'ROBOTS_LIST_REQUEST') ->
    1;
enum_to_int(robossrequest_type, 'WHEELS_CMD') -> 0.

int_to_enum(robossrequest_type, 5) -> 'RESET';
int_to_enum(robossrequest_type, 4) -> 'STOP';
int_to_enum(robossrequest_type, 3) -> 'START';
int_to_enum(robossrequest_type, 2) -> 'STATE_REQUEST';
int_to_enum(robossrequest_type, 1) ->
    'ROBOTS_LIST_REQUEST';
int_to_enum(robossrequest_type, 0) -> 'WHEELS_CMD';
int_to_enum(_, Val) -> Val.

decode_ack(Bytes) when is_binary(Bytes) ->
    decode(ack, Bytes).

decode_robotslist(Bytes) when is_binary(Bytes) ->
    decode(robotslist, Bytes).

decode_wheelscommand(Bytes) when is_binary(Bytes) ->
    decode(wheelscommand, Bytes).

decode_robossrequest(Bytes) when is_binary(Bytes) ->
    decode(robossrequest, Bytes).

decode_robotstate(Bytes) when is_binary(Bytes) ->
    decode(robotstate, Bytes).

delimited_decode_robotstate(Bytes) ->
    delimited_decode(robotstate, Bytes).

delimited_decode_robossrequest(Bytes) ->
    delimited_decode(robossrequest, Bytes).

delimited_decode_wheelscommand(Bytes) ->
    delimited_decode(wheelscommand, Bytes).

delimited_decode_robotslist(Bytes) ->
    delimited_decode(robotslist, Bytes).

delimited_decode_ack(Bytes) ->
    delimited_decode(ack, Bytes).

delimited_decode(Type, Bytes) when is_binary(Bytes) ->
    delimited_decode(Type, Bytes, []).

delimited_decode(_Type, <<>>, Acc) ->
    {lists:reverse(Acc), <<>>};
delimited_decode(Type, Bytes, Acc) ->
    try protobuffs:decode_varint(Bytes) of
      {Size, Rest} when size(Rest) < Size ->
	  {lists:reverse(Acc), Bytes};
      {Size, Rest} ->
	  <<MessageBytes:Size/binary, Rest2/binary>> = Rest,
	  Message = decode(Type, MessageBytes),
	  delimited_decode(Type, Rest2, [Message | Acc])
    catch
      _What:_Why -> {lists:reverse(Acc), Bytes}
    end.

decode(enummsg_values, 1) -> value1;
decode(robotstate, Bytes) when is_binary(Bytes) ->
    Types = [{4, timestamp, int64, []},
	     {3, theta, double, []}, {2, y, double, []},
	     {1, x, double, []}],
    Defaults = [],
    Decoded = decode(Bytes, Types, Defaults),
    to_record(robotstate, Decoded);
decode(robossrequest, Bytes) when is_binary(Bytes) ->
    Types = [{2, wheelscmd, wheelscommand, [is_record]},
	     {1, type, robossrequest_type, []}],
    Defaults = [],
    Decoded = decode(Bytes, Types, Defaults),
    to_record(robossrequest, Decoded);
decode(wheelscommand, Bytes) when is_binary(Bytes) ->
    Types = [{4, rearright, double, []},
	     {3, rearleft, double, []}, {2, frontright, double, []},
	     {1, frontleft, double, []}],
    Defaults = [],
    Decoded = decode(Bytes, Types, Defaults),
    to_record(wheelscommand, Decoded);
decode(robotslist, Bytes) when is_binary(Bytes) ->
    Types = [{1, robotnames, string, [repeated]}],
    Defaults = [{1, robotnames, []}],
    Decoded = decode(Bytes, Types, Defaults),
    to_record(robotslist, Decoded);
decode(ack, Bytes) when is_binary(Bytes) ->
    Types = [],
    Defaults = [],
    Decoded = decode(Bytes, Types, Defaults),
    to_record(ack, Decoded).

decode(<<>>, Types, Acc) ->
    reverse_repeated_fields(Acc, Types);
decode(Bytes, Types, Acc) ->
    {ok, FNum} = protobuffs:next_field_num(Bytes),
    case lists:keyfind(FNum, 1, Types) of
      {FNum, Name, Type, Opts} ->
	  {Value1, Rest1} = case lists:member(is_record, Opts) of
			      true ->
				  {{FNum, V}, R} = protobuffs:decode(Bytes,
								     bytes),
				  RecVal = decode(Type, V),
				  {RecVal, R};
			      false ->
				  case lists:member(repeated_packed, Opts) of
				    true ->
					{{FNum, V}, R} =
					    protobuffs:decode_packed(Bytes,
								     Type),
					{V, R};
				    false ->
					{{FNum, V}, R} =
					    protobuffs:decode(Bytes, Type),
					{unpack_value(V, Type), R}
				  end
			    end,
	  case lists:member(repeated, Opts) of
	    true ->
		case lists:keytake(FNum, 1, Acc) of
		  {value, {FNum, Name, List}, Acc1} ->
		      decode(Rest1, Types,
			     [{FNum, Name, [int_to_enum(Type, Value1) | List]}
			      | Acc1]);
		  false ->
		      decode(Rest1, Types,
			     [{FNum, Name, [int_to_enum(Type, Value1)]} | Acc])
		end;
	    false ->
		decode(Rest1, Types,
		       [{FNum, Name, int_to_enum(Type, Value1)} | Acc])
	  end;
      false ->
	  case lists:keyfind('$extensions', 2, Acc) of
	    {_, _, Dict} ->
		{{FNum, _V}, R} = protobuffs:decode(Bytes, bytes),
		Diff = size(Bytes) - size(R),
		<<V:Diff/binary, _/binary>> = Bytes,
		NewDict = dict:store(FNum, V, Dict),
		NewAcc = lists:keyreplace('$extensions', 2, Acc,
					  {false, '$extensions', NewDict}),
		decode(R, Types, NewAcc);
	    _ ->
		{ok, Skipped} = protobuffs:skip_next_field(Bytes),
		decode(Skipped, Types, Acc)
	  end
    end.

reverse_repeated_fields(FieldList, Types) ->
    [begin
       case lists:keyfind(FNum, 1, Types) of
	 {FNum, Name, _Type, Opts} ->
	     case lists:member(repeated, Opts) of
	       true -> {FNum, Name, lists:reverse(Value)};
	       _ -> Field
	     end;
	 _ -> Field
       end
     end
     || {FNum, Name, Value} = Field <- FieldList].

unpack_value(Binary, string) when is_binary(Binary) ->
    binary_to_list(Binary);
unpack_value(Value, _) -> Value.

to_record(robotstate, DecodedTuples) ->
    Record1 = lists:foldr(fun ({_FNum, Name, Val},
			       Record) ->
				  set_record_field(record_info(fields,
							       robotstate),
						   Record, Name, Val)
			  end,
			  #robotstate{}, DecodedTuples),
    Record1;
to_record(robossrequest, DecodedTuples) ->
    Record1 = lists:foldr(fun ({_FNum, Name, Val},
			       Record) ->
				  set_record_field(record_info(fields,
							       robossrequest),
						   Record, Name, Val)
			  end,
			  #robossrequest{}, DecodedTuples),
    Record1;
to_record(wheelscommand, DecodedTuples) ->
    Record1 = lists:foldr(fun ({_FNum, Name, Val},
			       Record) ->
				  set_record_field(record_info(fields,
							       wheelscommand),
						   Record, Name, Val)
			  end,
			  #wheelscommand{}, DecodedTuples),
    Record1;
to_record(robotslist, DecodedTuples) ->
    Record1 = lists:foldr(fun ({_FNum, Name, Val},
			       Record) ->
				  set_record_field(record_info(fields,
							       robotslist),
						   Record, Name, Val)
			  end,
			  #robotslist{}, DecodedTuples),
    Record1;
to_record(ack, DecodedTuples) ->
    Record1 = lists:foldr(fun ({_FNum, Name, Val},
			       Record) ->
				  set_record_field(record_info(fields, ack),
						   Record, Name, Val)
			  end,
			  #ack{}, DecodedTuples),
    Record1.

decode_extensions(Record) -> Record.

decode_extensions(_Types, [], Acc) ->
    dict:from_list(Acc);
decode_extensions(Types, [{Fnum, Bytes} | Tail], Acc) ->
    NewAcc = case lists:keyfind(Fnum, 1, Types) of
	       {Fnum, Name, Type, Opts} ->
		   {Value1, Rest1} = case lists:member(is_record, Opts) of
				       true ->
					   {{FNum, V}, R} =
					       protobuffs:decode(Bytes, bytes),
					   RecVal = decode(Type, V),
					   {RecVal, R};
				       false ->
					   case lists:member(repeated_packed,
							     Opts)
					       of
					     true ->
						 {{FNum, V}, R} =
						     protobuffs:decode_packed(Bytes,
									      Type),
						 {V, R};
					     false ->
						 {{FNum, V}, R} =
						     protobuffs:decode(Bytes,
								       Type),
						 {unpack_value(V, Type), R}
					   end
				     end,
		   case lists:member(repeated, Opts) of
		     true ->
			 case lists:keytake(FNum, 1, Acc) of
			   {value, {FNum, Name, List}, Acc1} ->
			       decode(Rest1, Types,
				      [{FNum, Name,
					lists:reverse([int_to_enum(Type, Value1)
						       | lists:reverse(List)])}
				       | Acc1]);
			   false ->
			       decode(Rest1, Types,
				      [{FNum, Name, [int_to_enum(Type, Value1)]}
				       | Acc])
			 end;
		     false ->
			 [{Fnum,
			   {optional, int_to_enum(Type, Value1), Type, Opts}}
			  | Acc]
		   end;
	       false -> [{Fnum, Bytes} | Acc]
	     end,
    decode_extensions(Types, Tail, NewAcc).

set_record_field(Fields, Record, '$extensions',
		 Value) ->
    Decodable = [],
    NewValue = decode_extensions(element(1, Record),
				 Decodable, dict:to_list(Value)),
    Index = list_index('$extensions', Fields),
    erlang:setelement(Index + 1, Record, NewValue);
set_record_field(Fields, Record, Field, Value) ->
    Index = list_index(Field, Fields),
    erlang:setelement(Index + 1, Record, Value).

list_index(Target, List) -> list_index(Target, List, 1).

list_index(Target, [Target | _], Index) -> Index;
list_index(Target, [_ | Tail], Index) ->
    list_index(Target, Tail, Index + 1);
list_index(_, [], _) -> -1.

extension_size(_) -> 0.

has_extension(_Record, _FieldName) -> false.

get_extension(_Record, _FieldName) -> undefined.

set_extension(Record, _, _) -> {error, Record}.

