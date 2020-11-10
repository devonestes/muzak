defmodule Muzak.Formatter do
  @moduledoc false
  # Contains all the stuff for formatting and printing of reports

  require ExUnit.Assertions

  alias Inspect.Algebra

  alias ExUnit.Diff

  @no_value :ex_unit_no_meaningful_value

  @counter_padding "     "

  @doc false
  # The start_link for our printer process
  def start_link() do
    group_leader = Process.group_leader()

    fn -> print_loop(group_leader) end
    |> spawn_link()
    |> Process.register(__MODULE__)
  end

  @doc false
  def print_report(report) do
    send(__MODULE__, {:finished, self()})

    receive do
      :done -> do_print_report(report)
    end
  end

  @doc false
  def do_print_report({:noop, _, time, _}) do
    print_time(time)
    IO.puts("Something went wrong - tests did not run for a later set of mutations!\n")
  end

  def do_print_report({:no_tests_run, _, time, _}) do
    print_time(time)
    IO.puts("Something went wrong - no tests were selected to be run!\n")
  end

  def do_print_report({[], num_mutations, time, _}) do
    print_time(time)
    IO.puts([IO.ANSI.green(), "#{num_mutations} run - 0 mutations survived", IO.ANSI.reset()])
  end

  def do_print_report({surviving_mutations, num_mutations, time, _}) do
    failure_info =
      surviving_mutations
      |> Enum.sort_by(&"#{&1.path}:#{&1.line}")
      |> Enum.reverse()
      |> Enum.reduce([], fn mutation_info, acc ->
        exception =
          try do
            ExUnit.Assertions.assert(mutation_info.mutation == mutation_info.original)
          rescue
            e -> e
          end

        case exception do
          true ->
            IO.warn("""
            Original and mutation were the same - something went wrong!
              file: #{mutation_info.path}:#{mutation_info.line}
            """)
            acc

          _ ->
            exception = %{
              exception
              | message: "#{mutation_info.path}:#{mutation_info.line}",
                expr: @no_value
            }

            ["\n", format_exception(exception) | acc]
        end
      end)

    IO.puts("")
    IO.puts(failure_info)
    print_time(time, "")
    msg = "#{num_mutations} mutations run - #{length(surviving_mutations)} mutations survived"
    IO.puts([IO.ANSI.red(), msg, IO.ANSI.reset()])
  end

  defp print_loop(group_leader) do
    receive do
      {:finished, caller} ->
        send(caller, :done)

      {:success, _} ->
        msg = IO.iodata_to_binary([IO.ANSI.green(), ".", IO.ANSI.reset()])
        IO.write(group_leader, msg)
        print_loop(group_leader)

      {:failure, _} ->
        msg = IO.iodata_to_binary([IO.ANSI.red(), "F", IO.ANSI.reset()])
        IO.write(group_leader, msg)
        print_loop(group_leader)

      {msg, node} ->
        if System.get_env("DEBUG"), do: IO.inspect(group_leader, msg, label: "#{node}")
        print_loop(group_leader)
    end
  end

  defp print_time(time, space \\ "\n") do
    IO.puts(space)

    time
    |> ExUnit.Formatter.format_time(nil)
    |> IO.puts()
  end

  defp format_exception(struct) do
    formatter = &formatter(&1, &2, %{colors: colors()})

    label_padding_size = 10
    padding_size = label_padding_size + byte_size(@counter_padding)

    formatted =
      [
        note: format_message(struct.message, formatter)
      ]
      |> Kernel.++(format_context(struct, formatter, padding_size, :infinity))
      |> format_meta(formatter, @counter_padding, label_padding_size)
      |> IO.iodata_to_binary()

    formatted
  end

  defp format_meta(fields, formatter, padding, padding_size) do
    for {label, value} <- fields, has_value?(value) do
      [padding, format_label(label, formatter, padding_size), value, "\n"]
    end
  end

  defp format_label(:note, _formatter, _padding_size), do: ""

  defp format_label(label, formatter, padding_size) do
    formatter.(:extra_info, String.pad_trailing("#{label}:", padding_size))
  end

  defp inspect_multiline(expr, padding_size, width) do
    expr
    |> Algebra.to_doc(%Inspect.Opts{width: width})
    |> Algebra.group()
    |> Algebra.nest(padding_size)
    |> Algebra.format(width)
  end

  defp format_sides(left, right, context, formatter, padding_size, width) do
    inspect = &inspect_multiline(&1, padding_size, width)

    case format_diff(left, right, context, formatter) do
      {result, _env} ->
        left = list_to_code(result.left, :delete)

        right = list_to_code(result.right, :insert)

        {left, right}

      nil ->
        {if_value(left, &code_multiline(&1, padding_size)), if_value(right, inspect)}
    end
  end

  defp format_diff(left, right, context, _) do
    if has_value?(left) and has_value?(right) do
      find_diff(left, right, context)
    end
  end

  defp find_diff(left, right, context) do
    task = Task.async(Diff, :compute, [left, right, context])

    case Task.yield(task, 1500) || Task.shutdown(task, :brutal_kill) do
      {:ok, diff} -> diff
      nil -> nil
    end
  end

  defp format_context(
         %{left: left, right: right, context: context},
         formatter,
         padding_size,
         width
       ) do
    {left, right} = format_sides(left, right, context, formatter, padding_size, width)
    [original: right, mutation: left]
  end

  defp has_value?(value) do
    value != @no_value
  end

  defp if_value(value, fun) do
    if has_value?(value) do
      fun.(value)
    else
      value
    end
  end

  defp code_multiline(expr, padding_size) do
    pad_multiline(Macro.to_string(expr), padding_size)
  end

  defp pad_multiline(expr, padding_size) when is_binary(expr) do
    padding = String.duplicate(" ", padding_size)
    String.replace(expr, "\n", "\n" <> padding)
  end

  defp format_message(value, formatter) do
    value = String.replace(value, "\n", "\n" <> @counter_padding)
    formatter.(:error_info, value)
  end

  defp formatter(:diff_enabled?, _, %{colors: colors}), do: colors[:enabled]

  defp formatter(:error_info, msg, config), do: colorize(:red, msg, config)

  defp formatter(:extra_info, msg, config), do: colorize(:cyan, msg, config)

  defp formatter(:location_info, msg, config), do: colorize([:bright, :black], msg, config)

  defp formatter(:diff_delete, doc, config), do: colorize_doc(:diff_delete, doc, config)

  defp formatter(:diff_delete_whitespace, doc, config),
    do: colorize_doc(:diff_delete_whitespace, doc, config)

  defp formatter(:diff_insert, doc, config), do: colorize_doc(:diff_insert, doc, config)

  defp formatter(:diff_insert_whitespace, doc, config),
    do: colorize_doc(:diff_insert_whitespace, doc, config)

  defp formatter(:blame_diff, msg, %{colors: colors} = config) do
    if colors[:enabled] do
      colorize(:red, msg, config)
    else
      "-" <> msg <> "-"
    end
  end

  defp formatter(_, msg, _config), do: msg

  defp colorize(escape, string, %{colors: colors}) do
    if colors[:enabled] do
      [escape, string, :reset]
      |> IO.ANSI.format_fragment(true)
      |> IO.iodata_to_binary()
    else
      string
    end
  end

  defp colorize_doc(escape, doc, %{colors: colors}) do
    if colors[:enabled] do
      Inspect.Algebra.color(doc, escape, %Inspect.Opts{syntax_colors: colors})
    else
      doc
    end
  end

  @default_colors [
    diff_delete: :red,
    diff_delete_whitespace: IO.ANSI.color_background(2, 0, 0),
    diff_insert: :green,
    diff_insert_whitespace: IO.ANSI.color_background(0, 2, 0)
  ]
  defp colors() do
    Keyword.put(@default_colors, :enabled, IO.ANSI.enabled?())
  end

  defp list_to_code(diff, atom) do
    after_fun = fn
      [] -> {:cont, []}
      {block, meta, acc} -> {:cont, {block, meta, Enum.reverse(acc)}, []}
    end

    code =
      if atom == :delete do
        "\e[31m"
      else
        "\e[32m"
      end

    result =
      diff
      |> Enum.flat_map(&flatten(&1, nil, nil))
      |> List.flatten()
      |> Enum.chunk_while({:__block__, [], []}, &do_chunk/2, after_fun)
      |> tl()
      |> Enum.map(fn {_, meta, strings} ->
        if meta[:diff] do
          "#{code}#{to_string(strings)}\e[0m"
        else
          to_string(strings)
        end
      end)
      |> to_string()
      |> String.replace(~r/\\"(?!.*\\")/, "\"")
      |> String.replace(~r/\\"(?!.*\\")/, "\"")
      |> String.replace("\\n", "\n")
      |> String.replace("\n", "\n               ")

    result
  end

  defp flatten({block, meta, args}, _, _) when is_list(args) do
    Enum.map(args, &flatten(&1, block, meta))
  end

  defp flatten(string, block, meta) when is_binary(string) do
    {block, meta, string}
  end

  defp do_chunk({block, meta, string}, {block, meta, strings}) do
    {:cont, {block, meta, [string | strings]}}
  end

  defp do_chunk({block, new_meta, string}, {block, meta, strings}) do
    {:cont, {block, meta, Enum.reverse(strings)}, {block, new_meta, [string]}}
  end
end
