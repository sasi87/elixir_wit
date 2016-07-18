defmodule Wit.Actions do
  @moduledoc """
  Wit.Actions is used to implement the default behaviour for the Wit which involves functions like
  `say, merge, error`. The macro `defaction` is also provided to define your own custom actions.
  When using `defaction` the name of the function is matched with the action returned from the
  converse API.

  ## Examples

      defmodule WeatherActions do
        use Wit.Actions

        def say(session, context, message) do
          # Send the message to the user
        end

        def error(session, context, error) do
          # Handle error
        end

        defaction fetch_weather(session, context) do
          context # Return the updated context
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      require Wit.Actions
      import Wit.Actions

      @behaviour Wit.DefaultActions

      @wit_actions %{"say" => :say, "error" => :error, "stop" => :stop}

      @before_compile Wit.Actions
    end
  end

  @doc """
  Defines a wit custom action

  ## Examples

      defaction fetch_weather(session, context) do
        # Fetch weather
        context # Return the updated context
      end
  """
  defmacro defaction(head, do: body) do
    {func_name, arg_list} = Macro.decompose_call(head)

    # Throw error if the argument list is not equal to 3
    if length(arg_list) != 3 do
      raise ArgumentError, message: "Wit action should have three arguments i.e. session, context, message"
    end

    quote do
      @wit_actions Map.put(@wit_actions, unquote(Atom.to_string(func_name)), unquote(func_name))

      def unquote(head) do
        unquote(body)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do

      def actions() do
        @wit_actions
      end

      def call_action(action, session, context, message) when action in ["say"] do
        call_action(action, [session, context, message])
      end

      def call_action(action, session, context) do
        call_action(action, [session, context])
      end

      defp call_action(action, arg_list) do
        wit_actions = @wit_actions
        func = Map.get(wit_actions, action)

        apply_action(func, arg_list)
      end

      defp apply_action(nil, _arg_list), do: {:error, "No action found"}
      defp apply_action(func, arg_list), do: apply(__MODULE__, func, arg_list)

    end
  end
end
