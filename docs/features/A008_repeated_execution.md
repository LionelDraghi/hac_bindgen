# A008 — Repeated script execution in the same HAC environment <!-- omit from toc -->

One HAC environment accepts multiple builds and executions on the
same `Build_Data` (M2 evidence, `make witness`): this page pins it
end to end through the e2e harness, in the shape a real embedding
takes — an application that runs script after script against its
registered bindings, with the bindings still resolving and each
script starting with fresh locals.

## Executable scenarios

| Scenario | Behavior |
|---|---|
| A008-01 | two scripts run in sequence in one HAC environment |

### Scenario: two scripts run in sequence in one HAC environment

The witness registers the binding once, then builds and interprets
each script argument in the same `Build_Data`; the second script
starts with fresh locals but sees the same bindings.

- Given the new directory `run`
- Given the new file `run/ping_api.ads` containing
  ```ada
  package Ping_Api is
     procedure Ping (X : in Integer);
  end Ping_Api;
  ```
- Given the new file `run/ping_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body Ping_Api is
     procedure Ping (X : in Integer) is
     begin
        Ada.Text_IO.Put_Line ("native: Ping" & Integer'Image (X));
     end Ping;
  end Ping_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/ping_api.ads --output-dir run --hac-package HAC_Ping_Api`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Ping_Api_Native;
  package Witness_Binding renames Ping_Api_Native;
  ```
- Given the new file `run/script_a.adb` containing
  ```ada
  with HAC_Ping_Api;
  procedure Script_A is
  begin
     HAC_Ping_Api.Ping (1);
  end Script_A;
  ```
- Given the new file `run/script_b.adb` containing
  ```ada
  with HAC_Ping_Api;
  procedure Script_B is
  begin
     HAC_Ping_Api.Ping (2);
  end Script_B;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/script_a.adb run/script_b.adb`
- Then I get
  ```text
  native: Ping 1
  E2E: script completed.
  native: Ping 2
  E2E: script completed.
  ```
