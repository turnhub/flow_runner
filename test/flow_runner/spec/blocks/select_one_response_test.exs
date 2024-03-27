defmodule FlowRunner.Spec.Blocks.SelectOneResponseTest do
  use ExUnit.Case
  alias FlowRunner.Spec.Blocks.SelectOneResponse

  test "evaluate_outgoing/5 selects the correct outgoing link when the user input is a string resembling a boolean" do
    flow = %FlowRunner.Spec.Flow{
      uuid: "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
      name: "stack",
      label: nil,
      last_modified: "2024-03-26T13:20:45.012220Z",
      interaction_timeout: 300,
      vendor_metadata: %{},
      supported_modes: ["RICH_MESSAGING"],
      first_block_id: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      exit_block_id: "",
      languages: [
        %FlowRunner.Spec.Language{
          id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
          iso_639_3: "eng",
          label: "English",
          variant: nil,
          bcp_47: nil
        }
      ],
      blocks: [
        %FlowRunner.Spec.Block{
          uuid: "37ce2c90-f5f7-5772-8464-b2a1553a78b8",
          name: "text_cf8c95_text",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 22},
                      "name" => "Text_cf8c95",
                      "uuid" => "1a0d7b02-cf4e-5541-9d0e-8c0623a72b6a"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 23},
                      "text" => %{},
                      "type" => "text"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.Message",
          config: %{prompt: "0413082a-9755-4731-8dd4-d93e8e878d8a"},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "6e45986e-e6bf-452f-b76c-679355661383",
              name: "text_cf8c95_text",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "5827c3fd-5e31-594a-a5a5-e7c92c7210fd",
          name: "text_57cef1_text",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 18},
                      "name" => "Text_57cef1",
                      "uuid" => "186d5e71-261e-5dd9-9881-216b7893eb4e"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 19},
                      "text" => %{},
                      "type" => "text"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.Message",
          config: %{prompt: "c5606e1b-b0ca-45a1-8e48-5e633eb7f220"},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "f7caa007-92b4-4713-a83a-98f05cf212bd",
              name: "text_57cef1_text",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "3dd88151-96d1-5e76-aad2-13d5f02b77ff",
          name: "reserved_default_card_text",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 26},
                      "name" => "RESERVED_DEFAULT_CARD",
                      "uuid" => "4bc4ef82-1e69-5862-9444-51e34f92d3c2"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 27},
                      "text" => %{},
                      "type" => "text"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.Message",
          config: %{prompt: "11d5d8be-43d9-4e7f-baa3-18b972e51d01"},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "dee36a6f-69ac-481e-aacf-e31e50e4070b",
              name: "reserved_default_card_text",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "be115dce-1f85-515c-9494-95bf3f00e87d",
          name: "text_4dd50b_text",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 14},
                      "name" => "Text_4dd50b",
                      "uuid" => "408621e5-7491-537b-b99b-a8731adbbc1a"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 15},
                      "text" => %{},
                      "type" => "text"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.Message",
          config: %{prompt: "ede492cb-7145-4843-af91-4036456f484a"},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "688c098a-6da7-4409-935c-8af3130c10fc",
              name: "text_4dd50b_text",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
          name: "ref_Buttons_7bef16",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "buttons_metadata" => %{},
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 3},
                      "name" => "Buttons_7bef16",
                      "uuid" => "e74b7a5d-65ea-5541-9585-cd1f2a2d62c3"
                    },
                    "card_item" => %{
                      "button_block" => %{},
                      "meta" => %{"column" => 3, "line" => 4},
                      "type" => "button_block"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.SelectOneResponse",
          config: %{
            prompt: "aa9d2ff7-0db2-44f9-8074-aece760795a5",
            choices: [
              %{
                name: "True",
                prompt: "48e95d58-a623-46fd-93c7-0a2674111d1c",
                test: "block.response = \"True\""
              },
              %{
                name: "2",
                prompt: "ae97bb77-8f80-4b93-b51f-d7b1e96e5eeb",
                test: "block.response = 2"
              },
              %{
                name: "Button 3",
                prompt: "86271754-00e8-4f9f-bafb-68abdbb74350",
                test: "block.response = \"Button 3\""
              }
            ]
          },
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "bd90534c-7974-466a-a50d-532efd7104ea",
              name: "ref_Buttons_7bef16",
              destination_block: "528d89f0-7b69-5b93-9376-a6c41ac3ac22",
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "528d89f0-7b69-5b93-9376-a6c41ac3ac22",
          name: "Routing for Buttons_7bef16",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 3},
                      "name" => "Buttons_7bef16",
                      "uuid" => "e74b7a5d-65ea-5541-9585-cd1f2a2d62c3"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 9},
                      "then" => %{},
                      "type" => "then"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "Core.Case",
          config: %{},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "dff8ba17-d73d-4607-91de-dca8b2ed8630",
              name: "Exit for Text_4dd50b",
              destination_block: "be115dce-1f85-515c-9494-95bf3f00e87d",
              semantic_label: nil,
              test: "ref_Buttons_7bef16 == \"True\"",
              default: false,
              config: %{},
              vendor_metadata: %{}
            },
            %FlowRunner.Spec.Exit{
              uuid: "dd605033-ef05-4edd-9170-1adb1a8c45a5",
              name: "Exit for Text_cf8c95",
              destination_block: "37ce2c90-f5f7-5772-8464-b2a1553a78b8",
              semantic_label: nil,
              test: "ref_Buttons_7bef16 == \"2\"",
              default: false,
              config: %{},
              vendor_metadata: %{}
            },
            %FlowRunner.Spec.Exit{
              uuid: "9eb3c26d-fb83-4784-99da-003e156279b3",
              name: "Exit for Text_57cef1",
              destination_block: "5827c3fd-5e31-594a-a5a5-e7c92c7210fd",
              semantic_label: nil,
              test: "ref_Buttons_7bef16 == \"Button 3\"",
              default: false,
              config: %{},
              vendor_metadata: %{}
            },
            %FlowRunner.Spec.Exit{
              uuid: "6c20dd20-92b4-4e53-b651-9d9c2a484fc2",
              name: "Routing for Buttons_7bef16",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        }
      ]
    }

    container = %FlowRunner.Spec.Container{
      specification_version: "1.0.0-rc3",
      uuid: "2894759f-7aa0-4875-8929-2c5999bee38d",
      name: "Journey 2",
      description: "Default description",
      flows: [flow],
      resources: [
        %FlowRunner.Spec.Resource{
          uuid: "0413082a-9755-4731-8dd4-d93e8e878d8a",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "You clicked button 2"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "c5606e1b-b0ca-45a1-8e48-5e633eb7f220",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "You clicked button 3"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "11d5d8be-43d9-4e7f-baa3-18b972e51d01",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "The button is not linked with any card. Please link a card to proceed."
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "ede492cb-7145-4843-af91-4036456f484a",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "You clicked button 1"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "aa9d2ff7-0db2-44f9-8074-aece760795a5",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "Boolean buttons test"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "48e95d58-a623-46fd-93c7-0a2674111d1c",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "True"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "ae97bb77-8f80-4b93-b51f-d7b1e96e5eeb",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "2"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "86271754-00e8-4f9f-bafb-68abdbb74350",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "Button 3"
            }
          ]
        }
      ],
      vendor_metadata: %{}
    }

    block = %FlowRunner.Spec.Block{
      uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      name: "ref_Buttons_7bef16",
      label: nil,
      semantic_label: nil,
      tags: [],
      vendor_metadata: %{
        "io" => %{
          "turn" => %{
            "stacks_dsl" => %{
              "0.1.0" => %{
                "buttons_metadata" => %{},
                "card" => %{
                  "condition" => nil,
                  "meta" => %{"column" => 1, "line" => 3},
                  "name" => "Buttons_7bef16",
                  "uuid" => "e74b7a5d-65ea-5541-9585-cd1f2a2d62c3"
                },
                "card_item" => %{
                  "button_block" => %{},
                  "meta" => %{"column" => 3, "line" => 4},
                  "type" => "button_block"
                },
                "index" => 0
              }
            }
          }
        }
      },
      ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
      type: "MobilePrimitives.SelectOneResponse",
      config: %{
        prompt: "aa9d2ff7-0db2-44f9-8074-aece760795a5",
        choices: [
          %{
            name: "True",
            prompt: "48e95d58-a623-46fd-93c7-0a2674111d1c",
            test: "block.response = \"True\""
          },
          %{
            name: "2",
            prompt: "ae97bb77-8f80-4b93-b51f-d7b1e96e5eeb",
            test: "block.response = 2"
          },
          %{
            name: "Button 3",
            prompt: "86271754-00e8-4f9f-bafb-68abdbb74350",
            test: "block.response = \"Button 3\""
          }
        ]
      },
      exits: [
        %FlowRunner.Spec.Exit{
          uuid: "bd90534c-7974-466a-a50d-532efd7104ea",
          name: "ref_Buttons_7bef16",
          destination_block: "528d89f0-7b69-5b93-9376-a6c41ac3ac22",
          semantic_label: "",
          test: "",
          default: true,
          config: %{},
          vendor_metadata: %{}
        }
      ]
    }

    context = %FlowRunner.Context{
      language: "eng",
      mode: "RICH_MESSAGING",
      log: [],
      waiting_for_user_input: true,
      current_flow_uuid: "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
      last_block_uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      vars: %{
        "flow" => %{
          "__value__" => "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
          "uuid" => "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd"
        }
      },
      private: %{},
      finished: false,
      waiting_for_child_flow: false,
      child_flow_uuid: nil,
      parent_flow_uuid: nil,
      parent_state_uuid: nil
    }

    user_input = "True"

    assert {:ok, %{"__value__" => "True", "index" => 0, "label" => "True", "name" => "True"}} =
             SelectOneResponse.evaluate_outgoing(container, flow, block, context, user_input)
  end

  test "evaluate_outgoing/5 selects the correct outgoing link when the user input is a string resembling a number" do
    flow = %FlowRunner.Spec.Flow{
      uuid: "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
      name: "stack",
      label: nil,
      last_modified: "2024-03-26T13:20:45.012220Z",
      interaction_timeout: 300,
      vendor_metadata: %{},
      supported_modes: ["RICH_MESSAGING"],
      first_block_id: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      exit_block_id: "",
      languages: [
        %FlowRunner.Spec.Language{
          id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
          iso_639_3: "eng",
          label: "English",
          variant: nil,
          bcp_47: nil
        }
      ],
      blocks: [
        %FlowRunner.Spec.Block{
          uuid: "37ce2c90-f5f7-5772-8464-b2a1553a78b8",
          name: "text_cf8c95_text",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 22},
                      "name" => "Text_cf8c95",
                      "uuid" => "1a0d7b02-cf4e-5541-9d0e-8c0623a72b6a"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 23},
                      "text" => %{},
                      "type" => "text"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.Message",
          config: %{prompt: "0413082a-9755-4731-8dd4-d93e8e878d8a"},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "6e45986e-e6bf-452f-b76c-679355661383",
              name: "text_cf8c95_text",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "5827c3fd-5e31-594a-a5a5-e7c92c7210fd",
          name: "text_57cef1_text",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 18},
                      "name" => "Text_57cef1",
                      "uuid" => "186d5e71-261e-5dd9-9881-216b7893eb4e"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 19},
                      "text" => %{},
                      "type" => "text"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.Message",
          config: %{prompt: "c5606e1b-b0ca-45a1-8e48-5e633eb7f220"},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "f7caa007-92b4-4713-a83a-98f05cf212bd",
              name: "text_57cef1_text",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "3dd88151-96d1-5e76-aad2-13d5f02b77ff",
          name: "reserved_default_card_text",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 26},
                      "name" => "RESERVED_DEFAULT_CARD",
                      "uuid" => "4bc4ef82-1e69-5862-9444-51e34f92d3c2"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 27},
                      "text" => %{},
                      "type" => "text"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.Message",
          config: %{prompt: "11d5d8be-43d9-4e7f-baa3-18b972e51d01"},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "dee36a6f-69ac-481e-aacf-e31e50e4070b",
              name: "reserved_default_card_text",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "be115dce-1f85-515c-9494-95bf3f00e87d",
          name: "text_4dd50b_text",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 14},
                      "name" => "Text_4dd50b",
                      "uuid" => "408621e5-7491-537b-b99b-a8731adbbc1a"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 15},
                      "text" => %{},
                      "type" => "text"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.Message",
          config: %{prompt: "ede492cb-7145-4843-af91-4036456f484a"},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "688c098a-6da7-4409-935c-8af3130c10fc",
              name: "text_4dd50b_text",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
          name: "ref_Buttons_7bef16",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "buttons_metadata" => %{},
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 3},
                      "name" => "Buttons_7bef16",
                      "uuid" => "e74b7a5d-65ea-5541-9585-cd1f2a2d62c3"
                    },
                    "card_item" => %{
                      "button_block" => %{},
                      "meta" => %{"column" => 3, "line" => 4},
                      "type" => "button_block"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "MobilePrimitives.SelectOneResponse",
          config: %{
            prompt: "aa9d2ff7-0db2-44f9-8074-aece760795a5",
            choices: [
              %{
                name: "True",
                prompt: "48e95d58-a623-46fd-93c7-0a2674111d1c",
                test: "block.response = \"True\""
              },
              %{
                name: "2",
                prompt: "ae97bb77-8f80-4b93-b51f-d7b1e96e5eeb",
                test: "block.response = 2"
              },
              %{
                name: "Button 3",
                prompt: "86271754-00e8-4f9f-bafb-68abdbb74350",
                test: "block.response = \"Button 3\""
              }
            ]
          },
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "bd90534c-7974-466a-a50d-532efd7104ea",
              name: "ref_Buttons_7bef16",
              destination_block: "528d89f0-7b69-5b93-9376-a6c41ac3ac22",
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        },
        %FlowRunner.Spec.Block{
          uuid: "528d89f0-7b69-5b93-9376-a6c41ac3ac22",
          name: "Routing for Buttons_7bef16",
          label: nil,
          semantic_label: nil,
          tags: [],
          vendor_metadata: %{
            "io" => %{
              "turn" => %{
                "stacks_dsl" => %{
                  "0.1.0" => %{
                    "card" => %{
                      "condition" => nil,
                      "meta" => %{"column" => 1, "line" => 3},
                      "name" => "Buttons_7bef16",
                      "uuid" => "e74b7a5d-65ea-5541-9585-cd1f2a2d62c3"
                    },
                    "card_item" => %{
                      "meta" => %{"column" => 3, "line" => 9},
                      "then" => %{},
                      "type" => "then"
                    },
                    "index" => 0
                  }
                }
              }
            }
          },
          ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
          type: "Core.Case",
          config: %{},
          exits: [
            %FlowRunner.Spec.Exit{
              uuid: "dff8ba17-d73d-4607-91de-dca8b2ed8630",
              name: "Exit for Text_4dd50b",
              destination_block: "be115dce-1f85-515c-9494-95bf3f00e87d",
              semantic_label: nil,
              test: "ref_Buttons_7bef16 == \"True\"",
              default: false,
              config: %{},
              vendor_metadata: %{}
            },
            %FlowRunner.Spec.Exit{
              uuid: "dd605033-ef05-4edd-9170-1adb1a8c45a5",
              name: "Exit for Text_cf8c95",
              destination_block: "37ce2c90-f5f7-5772-8464-b2a1553a78b8",
              semantic_label: nil,
              test: "ref_Buttons_7bef16 == \"2\"",
              default: false,
              config: %{},
              vendor_metadata: %{}
            },
            %FlowRunner.Spec.Exit{
              uuid: "9eb3c26d-fb83-4784-99da-003e156279b3",
              name: "Exit for Text_57cef1",
              destination_block: "5827c3fd-5e31-594a-a5a5-e7c92c7210fd",
              semantic_label: nil,
              test: "ref_Buttons_7bef16 == \"Button 3\"",
              default: false,
              config: %{},
              vendor_metadata: %{}
            },
            %FlowRunner.Spec.Exit{
              uuid: "6c20dd20-92b4-4e53-b651-9d9c2a484fc2",
              name: "Routing for Buttons_7bef16",
              destination_block: nil,
              semantic_label: "",
              test: "",
              default: true,
              config: %{},
              vendor_metadata: %{}
            }
          ]
        }
      ]
    }

    container = %FlowRunner.Spec.Container{
      specification_version: "1.0.0-rc3",
      uuid: "2894759f-7aa0-4875-8929-2c5999bee38d",
      name: "Journey 2",
      description: "Default description",
      flows: [flow],
      resources: [
        %FlowRunner.Spec.Resource{
          uuid: "0413082a-9755-4731-8dd4-d93e8e878d8a",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "You clicked button 2"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "c5606e1b-b0ca-45a1-8e48-5e633eb7f220",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "You clicked button 3"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "11d5d8be-43d9-4e7f-baa3-18b972e51d01",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "The button is not linked with any card. Please link a card to proceed."
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "ede492cb-7145-4843-af91-4036456f484a",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "You clicked button 1"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "aa9d2ff7-0db2-44f9-8074-aece760795a5",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "Boolean buttons test"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "48e95d58-a623-46fd-93c7-0a2674111d1c",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "True"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "ae97bb77-8f80-4b93-b51f-d7b1e96e5eeb",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "2"
            }
          ]
        },
        %FlowRunner.Spec.Resource{
          uuid: "86271754-00e8-4f9f-bafb-68abdbb74350",
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: "d1c09571-c321-4e1d-8d68-efb7607abe26",
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: ["RICH_MESSAGING"],
              value: "Button 3"
            }
          ]
        }
      ],
      vendor_metadata: %{}
    }

    block = %FlowRunner.Spec.Block{
      uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      name: "ref_Buttons_7bef16",
      label: nil,
      semantic_label: nil,
      tags: [],
      vendor_metadata: %{
        "io" => %{
          "turn" => %{
            "stacks_dsl" => %{
              "0.1.0" => %{
                "buttons_metadata" => %{},
                "card" => %{
                  "condition" => nil,
                  "meta" => %{"column" => 1, "line" => 3},
                  "name" => "Buttons_7bef16",
                  "uuid" => "e74b7a5d-65ea-5541-9585-cd1f2a2d62c3"
                },
                "card_item" => %{
                  "button_block" => %{},
                  "meta" => %{"column" => 3, "line" => 4},
                  "type" => "button_block"
                },
                "index" => 0
              }
            }
          }
        }
      },
      ui_metadata: %{"canvas_coordinates" => %{"x" => 0, "y" => 0}},
      type: "MobilePrimitives.SelectOneResponse",
      config: %{
        prompt: "aa9d2ff7-0db2-44f9-8074-aece760795a5",
        choices: [
          %{
            name: "True",
            prompt: "48e95d58-a623-46fd-93c7-0a2674111d1c",
            test: "block.response = \"True\""
          },
          %{
            name: "2",
            prompt: "ae97bb77-8f80-4b93-b51f-d7b1e96e5eeb",
            test: "block.response = 2"
          },
          %{
            name: "Button 3",
            prompt: "86271754-00e8-4f9f-bafb-68abdbb74350",
            test: "block.response = \"Button 3\""
          }
        ]
      },
      exits: [
        %FlowRunner.Spec.Exit{
          uuid: "bd90534c-7974-466a-a50d-532efd7104ea",
          name: "ref_Buttons_7bef16",
          destination_block: "528d89f0-7b69-5b93-9376-a6c41ac3ac22",
          semantic_label: "",
          test: "",
          default: true,
          config: %{},
          vendor_metadata: %{}
        }
      ]
    }

    context = %FlowRunner.Context{
      language: "eng",
      mode: "RICH_MESSAGING",
      log: [],
      waiting_for_user_input: true,
      current_flow_uuid: "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
      last_block_uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      vars: %{
        "flow" => %{
          "__value__" => "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
          "uuid" => "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd"
        }
      },
      private: %{},
      finished: false,
      waiting_for_child_flow: false,
      child_flow_uuid: nil,
      parent_flow_uuid: nil,
      parent_state_uuid: nil
    }

    user_input = "2"

    assert {:ok, %{"__value__" => "2", "index" => 1, "label" => "2", "name" => "2"}} =
             SelectOneResponse.evaluate_outgoing(container, flow, block, context, user_input)
  end
end
