run "valid_string_concat" {
  command = plan

  variables {
    example_input = "test-val"
  }

  assert {
    condition     = output.example == "example-test-val"
    error_message = "Output value does not match expected value"
  }
}
