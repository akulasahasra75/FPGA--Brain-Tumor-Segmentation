# Nexys 4 DDR Reference Manual

> **Important:** This page was created for the Nexys 4 DDR board, revisions A–C. The Nexys 4 DDR has since been rebranded as the **Nexys A7**, starting in 2018 with revision D. See the Nexys A7 Resource Center for up-to-date materials.

The Nexys 4 DDR board is a complete, ready-to-use digital circuit development platform based on the latest **Artix-7™ FPGA** from Xilinx® (part number `XC7A100T-1CSG324C`). With its large, high-capacity FPGA, generous external memories, and collection of USB, Ethernet, and other ports, the Nexys 4 DDR can host designs ranging from introductory combinational circuits to powerful embedded processors.

---

## Features

- 15,850 logic slices, each with four 6-input LUTs and 8 flip-flops
- 4,860 Kbits of fast block RAM
- Six clock management tiles, each with a phase-locked loop (PLL)
- 240 DSP slices
- Internal clock speeds exceeding 450 MHz
- On-chip analog-to-digital converter (XADC)
- 16 user switches and 16 user LEDs
- Two tri-color LEDs
- USB-UART Bridge
- 12-bit VGA output
- 3-axis accelerometer
- 128 MiB DDR2
- Pmod port for XADC signals
- PWM audio output
- Temperature sensor
- Serial Flash
- Digilent USB-JTAG port for FPGA programming and communication
- Two 4-digit 7-segment displays (configured as a single 8-digit display)
- Micro SD card connector
- PDM microphone
- 10/100 Ethernet PHY
- Four Pmod ports
- USB HID Host for mice, keyboards, and memory sticks

The Nexys 4 DDR is compatible with Xilinx's **Vivado® Design Suite** as well as the **ISE® toolset** (including ChipScope™ and EDK). Xilinx offers free WebPACK™ versions of these toolsets so designs can be implemented at no additional cost.

---

## Board Component Reference

| Callout | Component Description                  | Callout | Component Description                |
| ------- | -------------------------------------- | ------- | ------------------------------------ |
| 1       | Power select jumper and battery header | 13      | FPGA configuration reset button      |
| 2       | Shared UART/JTAG USB port              | 14      | CPU reset button (for soft cores)    |
| 3       | External configuration jumper (SD/USB) | 15      | Analog signal Pmod port (XADC)       |
| 4       | Pmod port(s)                           | 16      | Programming mode jumper              |
| 5       | Microphone                             | 17      | Audio connector                      |
| 6       | Power supply test point(s)             | 18      | VGA connector                        |
| 7       | LEDs (16)                              | 19      | FPGA programming done LED            |
| 8       | Slide switches                         | 20      | Ethernet connector                   |
| 9       | Eight-digit 7-segment display          | 21      | USB host connector                   |
| 10      | JTAG port for optional external cable  | 22      | PIC24 programming port (factory use) |
| 11      | Five pushbuttons                       | 23      | Power switch                         |
| 12      | Temperature sensor                     | 24      | Power jack                           |

---

## 1. Migrating from Nexys 4

The Nexys 4 DDR is an incremental update to the Nexys 4 board. The major improvement is the replacement of the 16 MiB CellularRAM with a **128 MiB DDR2 SDRAM**. Digilent provides a VHDL reference module that wraps the complexity of a DDR2 controller and is backwards compatible with the asynchronous SRAM interface of the CellularRAM (with certain limitations).

To accommodate the new memory, the pin-out of the FPGA banks has changed. The constraints file of existing projects will need to be updated.

> **Note:** The audio output (`AUD_PWM`) needs to be driven **open-drain** as opposed to push-pull on the Nexys 4.

---

## 2. Power Supplies

The Nexys 4 DDR board can receive power from the Digilent USB-JTAG port (J6) or from an external power supply. Jumper **JP3** (near the power jack) determines which source is used.

All power supplies are controlled by a single logic-level power switch (**SW16**). A power-good LED (**LD22**) indicates that the supplies are operating normally.

- **USB power** is sufficient for most designs (the out-of-box demo draws ~400 mA from the 5V rail).
- **External power supply:** Use the power jack (JP3) and set jumper J13 to "wall." The supply must use a coax, center-positive 2.1 mm internal-diameter plug, delivering **4.5–5.5 VDC** at **≥ 1A**.
- **External battery pack:** Connect to JP3 (positive) and J12 (negative). Must not exceed **5.5 VDC**. Minimum voltage is 3.6 V (or 4.6 V if USB Host is used).

### Table 1 — Nexys 4 DDR Power Supplies

| Supply | Circuits                                                     | Device        | Current (max / typical) |
| ------ | ------------------------------------------------------------ | ------------- | ----------------------- |
| 3.3V   | FPGA I/O, USB, Clocks, RAM I/O, Ethernet, SD, Sensors, Flash | IC17: ADP2118 | 3A / 0.1–1.5A           |
| 1.0V   | FPGA Core                                                    | IC22: ADP2118 | 3A / 0.2–1.3A           |
| 1.8V   | DDR2, FPGA Auxiliary and RAM                                 | IC23: ADP2118 | 0.8A / 0.5A             |

### 2.1 Protection

A **3.5A fuse** (R287) and a **5V Zener diode** (D16) provide non-resettable overcurrent and overvoltage protection. Applying power outside of the specified range may permanently damage these components and is not covered by warranty.

---

## 3. FPGA Configuration

After power-on, the Artix-7 FPGA must be configured before it can perform any functions. There are four configuration methods:

1. **JTAG** — A PC programs the FPGA via the Digilent USB-JTAG circuitry (J6) any time power is on.
2. **Quad-SPI Flash** — A bitstream stored in the non-volatile SPI flash device is transferred to the FPGA.
3. **Micro SD Card** — A bitstream is loaded from a micro SD card inserted into J1.
4. **USB Memory Stick** — A bitstream is loaded from a USB drive attached to the USB HID port.

Configuration data is stored in files called **bitstreams** (`.bit` extension), created by ISE or Vivado from VHDL, Verilog, or schematic source files. Bitstream data remains valid until removed by power-down, pressing the PROG reset button, or writing a new configuration via JTAG.

> An Artix-7 100T bitstream is typically **30,606,304 bits**. Enabling bitstream compression within the Xilinx tools can achieve compression ratios of up to **10×**, significantly reducing programming time.

### 3.1 JTAG Configuration

During JTAG programming, a `.bit` file is transferred from the PC to the FPGA using the onboard USB-JTAG circuitry (J6) or an external programmer (e.g., Digilent JTAG-HS2) attached to J10. Programming an uncompressed bitstream typically takes around **five seconds**.

### 3.2 Quad-SPI Configuration

The FPGA uses the Quad-SPI flash to store configuration between power cycles (**Master SPI mode**). Programming the flash uses **indirect programming** — the FPGA is first loaded with a flash-programming circuit, then data is transferred to the flash. Once written, configuration at power-on takes **less than a second**.

- Flash programming can take **4–5 minutes** due to the erase process.
- Supports x1, x2, and x4 bus widths at up to **50 MHz**.

### 3.3 USB Host and Micro SD Programming

To program from a USB drive or microSD card:

1. Format the storage device with a **FAT32** file system.
2. Place a single `.bit` configuration file in the **root directory**.
3. Attach the storage device to the Nexys 4 DDR.
4. Set jumper **JP1** to `USB/SD`.
5. Select the desired storage device using **JP2**.
6. Press the **PROG** button or power-cycle the board.

**BUSY LED status during configuration:**

| LED Behavior | Meaning                                           |
| ------------ | ------------------------------------------------- |
| Steady on    | Microcontroller booting or downloading bitstream  |
| Slow pulse   | Waiting for a configuration medium to be inserted |
| Rapid blink  | Error during configuration                        |

---

## 4. Memory

The Nexys 4 DDR contains two external memories: a **1 Gib (128 MiB) DDR2 SDRAM** and a **128 Mib (16 MiB) non-volatile serial Flash**.

### 4.1 DDR2

The board includes one **Micron MT47H64M16HR-25:H** DDR2 component — a single rank, 16-bit wide interface routed to a 1.8V HR FPGA bank with 50-ohm controlled impedance.

There are two recommended ways to use the DDR2:

- **Digilent DDR-to-SRAM adapter module** — Instantiates the memory controller with an asynchronous SRAM bus interface. Provides backward compatibility with older Nexys boards; trades bandwidth for simplicity.
- **Xilinx MIG (Memory Interface Generator) Wizard** — Generates a native FIFO-style or AXI4 interface. Allows full customization of DDR parameters.

#### Table 2 — DDR2 MIG Wizard Settings

| Setting                        | Value              |
| ------------------------------ | ------------------ |
| Memory type                    | DDR2 SDRAM         |
| Max. clock period              | 3000 ps (667 Mbps) |
| Recommended clock period       | 3077 ps (650 Mbps) |
| Memory part                    | MT47H64M16HR-25E   |
| Data width                     | 16                 |
| Data mask                      | Enabled            |
| Chip Select pin                | Enabled            |
| Rtt (on-die termination)       | 50 ohms            |
| Internal Vref                  | Enabled            |
| Internal termination impedance | 50 ohms            |

> For more details, refer to: [7 Series FPGAs Memory Interface Solutions User Guide (UG586)](https://docs.xilinx.com/v/u/2.1-English/ug586_7Series_MIS)

### 4.2 Quad-SPI Flash

Configuration files are stored in the **Spansion S25FL128S** Quad-SPI Flash. An Artix-7 100T configuration file uses just under 4 MiB, leaving ~77% of the flash available for user data. All SPI bus signals except `SCK` are general-purpose I/O pins after configuration. `SCK` is accessed via the `STARTUPE2` FPGA primitive.

---

## 5. Ethernet PHY

The Nexys 4 DDR includes an **SMSC LAN8720A** 10/100 Ethernet PHY paired with an RJ-45 jack with integrated magnetics. It uses the **RMII interface** and supports 10/100 Mb/s.

**Power-on defaults:**

- RMII mode interface
- Auto-negotiation enabled (advertising all 10/100 modes)
- PHY address = `00001`

Two on-board LEDs (LD23, LD24) indicate link status and data activity.

> Reference: [LAN8720A Datasheet](http://ww1.microchip.com/downloads/en/DeviceDoc/8720a.pdf)

---

## 6. Oscillators / Clocks

The Nexys 4 DDR includes a single **100 MHz crystal oscillator** connected to pin **E3** (a MRCC input on bank 35). This clock can drive MMCMs or PLLs to generate clocks of various frequencies and phase relationships.

Xilinx's **Clocking Wizard IP core** simplifies clock generation by properly instantiating the required MMCMs and PLLs based on user-specified frequencies and phase relationships.

---

## 7. USB-UART Bridge (Serial Port)

An **FTDI FT2232HQ** USB-UART bridge (connector J6) enables PC communication using standard COM port commands. Serial data is exchanged using a two-wire port (TXD/RXD) with optional hardware flow control (RTS/CTS) on FPGA pins **C4** and **D4**.

- **LD20** — Transmit LED
- **LD19** — Receive LED

The FT2232HQ also serves as the USB-JTAG controller. The two functions are fully independent and can operate simultaneously over a single Micro USB cable.

---

## 8. USB HID Host

A **Microchip PIC24FJ128** microcontroller provides USB Embedded HID host capability. After the FPGA is programmed, the microcontroller switches to application mode and can drive a mouse or keyboard connected to the Type-A USB connector at J5 ("USB Host").

> **Limitations:** Hub support is not available. Only a single mouse or keyboard with a Boot HID interface is supported at a time.

### 8.1 HID Controller

The microcontroller hides the USB HID protocol from the FPGA and emulates a **PS/2 bus**, allowing existing PS/2 IP cores to be reused. Both mouse and keyboard use 11-bit words (start bit + 8-bit data LSB first + odd parity + stop bit).

When a device is connected, a "self-test passed" command (`0xAA`) is sent to the host. The device type can be identified using the Read ID command (`0xF2`).

### 8.2 Keyboard

PS/2 keyboards use **scan codes** to communicate key presses. Key-down events send the scan code; key-up events send `F0` followed by the scan code. Extended keys send `E0` ahead of the scan code.

#### Table 3 — Keyboard Commands

| Command | Action                                               |
| ------- | ---------------------------------------------------- |
| `ED`    | Set Num Lock, Caps Lock, and Scroll Lock LEDs        |
| `EE`    | Echo (test) — keyboard returns `EE`                  |
| `F3`    | Set scan code repeat rate                            |
| `FE`    | Resend — keyboard re-sends the most recent scan code |
| `FF`    | Reset                                                |

### 8.3 Mouse

In stream mode, the mouse outputs three 11-bit words per movement event (33 bits total). Movement data uses a relative coordinate system: right = positive X, up = positive Y. The XS and YS bits are sign bits; XV and YV bits indicate overflow.

Microsoft IntelliMouse® extensions for mouse wheel reporting are also supported.

#### Table 4 — Mouse Commands

| Command | Action                 |
| ------- | ---------------------- |
| `EA`    | Set stream mode        |
| `F4`    | Enable data reporting  |
| `F5`    | Disable data reporting |
| `F3`    | Set mouse sample rate  |
| `FE`    | Resend last packet     |
| `FF`    | Reset                  |

---

## 9. VGA Port

The Nexys 4 DDR uses **14 FPGA signals** to create a VGA port with **4 bits per color** (4096 colors total) and two standard sync signals (HS and VS). Resistor-divider circuits create 16 signal levels each on red, green, and blue channels, producing color signals from 0V (off) to 0.7V (full on).

### 9.1 VGA System Timing

For **640×480 @ 60 Hz** with a 25 MHz pixel clock, a VGA controller must generate HS and VS timing signals and coordinate video data delivery. A horizontal-sync counter driven by the pixel clock generates HS timings; a vertical-sync counter incrementing with each HS pulse generates VS timings.

> For precise timing specifications and other resolutions, refer to documentation from the [VESA® organization](https://www.vesa.org).

---

## 10. Basic I/O

The Nexys 4 DDR includes:

- 2 tri-color LEDs
- 16 slide switches
- 5 pushbuttons (plus-sign layout) + 1 red CPU RESET button
- 16 individual user LEDs (anode-connected via 330-ohm resistors; driven high to illuminate)

The five plus-sign pushbuttons are momentary switches: low at rest, high when pressed. The CPU RESET button is inverted: high at rest, low when pressed.

### 10.1 Seven-Segment Display

Two four-digit common-anode 7-segment LED displays are configured as a single **8-digit display**. Segment cathodes (CA–CG) are shared across all digits; digit selection is made via the anode enable signals (AN0–AN7).

Both anode enables and cathode signals are **active-low**. A scanning controller refreshes all eight digits in a continuous loop at **1 KHz to 60 Hz** (recommended refresh period: 1–16 ms per full cycle).

### 10.2 Tri-Color LED

Each tri-color LED contains three internal LEDs (red, blue, green). Signals are driven through a transistor (which inverts them), so driving a signal **high** illuminates the corresponding color. Mixing colors produces combined hues (e.g., red + blue = purple).

> **Recommendation:** Use **PWM** when driving tri-color LEDs. Steady logic '1' produces uncomfortably bright output. Keep duty cycles at or below 50% and adjust per-channel duty cycles to expand the color palette.

---

## 11. Pmod Ports

Four 12-pin Pmod ports (2×6, 100-mil female connectors) each provide:

- 8 logic signals
- 2× 3.3V VCC (pins 6 and 12)
- 2× Ground (pins 5 and 11)
- Up to 1A of current on VCC and GND pins

### Table 5 — Pmod Pin Assignments

| Pmod JA   | Pmod JB   | Pmod JC  | Pmod JD  | Pmod XADC            |
| --------- | --------- | -------- | -------- | -------------------- |
| JA1: C17  | JB1: D14  | JC1: K1  | JD1: H4  | JXADC1: A13 (AD3P)   |
| JA2: D18  | JB2: F16  | JC2: F6  | JD2: H1  | JXADC2: A15 (AD10P)  |
| JA3: E18  | JB3: G16  | JC3: J2  | JD3: G1  | JXADC3: B16 (AD2P)   |
| JA4: G17  | JB4: H14  | JC4: G6  | JD4: G3  | JXADC4: B18 (AD11P)  |
| JA7: D17  | JB7: E16  | JC7: E7  | JD7: H2  | JXADC7: A14 (AD3N)   |
| JA8: E17  | JB8: F13  | JC8: J3  | JD8: G4  | JXADC8: A16 (AD10N)  |
| JA9: F18  | JB9: G13  | JC9: J4  | JD9: G2  | JXADC9: B17 (AD2N)   |
| JA10: G18 | JB10: H16 | JC10: E6 | JD10: F3 | JXADC10: A18 (AD11N) |

### 11.1 Dual Analog/Digital Pmod (JXADC)

The `JXADC` connector is wired to the **auxiliary analog input pins** of the FPGA's XADC. The eight signals are grouped into four differential pairs for improved analog noise immunity. Each pair has a partially loaded anti-alias filter (capacitors C60–C63 are unpopulated; users may load them manually).

The **XADC** is a dual-channel 12-bit ADC capable of **1 MSPS**, controlled via the Dynamic Reconfiguration Port (DRP), which also provides access to on-chip voltage monitors and a temperature sensor.

> **Note:** Coupled routing and anti-alias filters may limit data speeds when used for digital signals.

---

## 12. MicroSD Slot

The microSD slot (J1) is shared between the Auxiliary Function microcontroller and the FPGA. Before FPGA configuration, the microcontroller accesses the card via SPI. Once the FPGA is configured, the microcontroller relinquishes control and power-cycles the SD slot, enabling the FPGA to use the card in **SD native bus mode**.

The `SD_RESET` signal must be actively driven **low** by the FPGA to power the microSD card slot. SPI mode is also available if needed.

---

## 13. Temperature Sensor

The Nexys 4 DDR includes an **Analog Devices ADT7420** temperature sensor providing up to **16-bit resolution** with typical accuracy better than **±0.25°C**.

### 13.1 I²C Interface

The ADT7420 is an I²C slave device at address **`0x4B`**. Multi-byte registers (e.g., temperature and threshold registers) support auto-incrementing address access for efficient reads.

### 13.2 Open-Drain Outputs

Two open-drain outputs signal temperature threshold events:

- **INT pin** — Triggered when temperature leaves the range defined by `TLOW` (0x06:0x07) and `THIGH` (0x04:0x05).
- **CT pin** — Triggered when temperature exceeds the critical threshold in `TCRIT` (0x08:0x09).

Both pins require **internal FPGA pull-ups** when used.

### 13.3 Quick Start Operation

At power-up, a **two-byte read** (no register specification needed) returns the temperature MSB and LSB. To convert to Celsius:

```
Temperature (°C) = (16-bit two's complement value >> 3) × 0.0625
```

---

## 14. Accelerometer

The Nexys 4 DDR includes an **Analog Devices ADXL362** 3-axis MEMS accelerometer.

Key specifications:

- Power consumption: **< 2 μA** at 100 Hz output rate; **270 nA** in wake-up mode
- Always provides **12-bit output resolution** (8-bit format also available)
- Measurement ranges: **±2 g, ±4 g, ±8 g** (1 mg/LSB at ±2 g)
- Interface: **SPI**

### 14.1 SPI Interface

- Recommended clock: **1–5 MHz**
- SPI mode: **Mode 0** (CPOL = 0, CPHA = 0)
- All communications must specify a register address and read/write flag.

### 14.2 Interrupts

Built-in functions can trigger interrupts mapped to **INT1** or **INT2** pins. Both pins require **internal FPGA pull-ups** when used.

> Reference: [ADXL362 Datasheet](http://www.analog.com/adxl362)

---

## 15. Microphone

The Nexys 4 DDR includes an omnidirectional **Analog Devices ADMP421** MEMS microphone with:

- SNR: **61 dBA**
- Sensitivity: **−26 dBFS**
- Flat frequency response: **100 Hz – 15 kHz**
- Output format: **PDM (Pulse Density Modulation)**

### 15.1 Pulse Density Modulation (PDM)

In a PDM bitstream, `1` = positive pulse and `0` = negative pulse. PDM signals typically operate at **1–3 MHz**. The signal is generated via **delta-sigma modulation** — the average of the output bits equals the value of the input analog signal.

#### Table 6 — Delta-Sigma Modulator Example (0.4 Vdd input)

| Sum            | Integrator Out  | Flip-flop Output |
| -------------- | --------------- | ---------------- |
| 0.4 − 0 = 0.4  | 0 + 0.4 = 0.4   | 0                |
| 0.4 − 0 = 0.4  | 0.4 + 0.4 = 0.8 | 1                |
| 0.4 − 1 = −0.6 | 0.8 − 0.6 = 0.2 | 0                |
| 0.4 − 0 = 0.4  | 0.2 + 0.4 = 0.6 | 1                |
| 0.4 − 1 = −0.6 | 0.6 − 0.6 = 0   | 0                |
| 0.4 − 0 = 0.4  | 0 + 0.4 = 0.4   | 0                |
| 0.4 − 0 = 0.4  | 0.4 + 0.4 = 0.8 | 1                |
| 0.4 − 1 = −0.6 | 0.8 − 0.6 = 0.2 | 0                |

### 15.2 Microphone Digital Interface Timing

- Clock input range: **1–3.3 MHz**
- L/R Select: **Low** = data available on rising clock edge; **High** = falling edge
- Typical clock frequency: **2.4 MHz**

---

## 16. Mono Audio Output

The on-board audio jack (J8) is driven by a **Sallen-Key Butterworth Low-Pass 4th Order Filter** for mono audio output. The input (`AUD_PWM`) is connected to FPGA pin **A11**.

The signal must be:

- Driven **low** for logic `0`
- Left in **high-impedance** for logic `1` (an on-board pull-up to a clean 3.3V rail establishes logic `1`)

The low-pass filter acts as a reconstruction filter, converting PWM/PDM signals into an analog output voltage.

### 16.1 Pulse-Width Modulation (PWM)

A PWM signal is a chain of fixed-frequency pulses with variable widths. Passing it through a low-pass filter produces an analog voltage proportional to the average duty cycle.

- Filter 3dB frequency should be **at least 10× lower** than the PWM frequency.
- For audio up to **5 kHz**, the PWM frequency should be **≥ 50 kHz**.

---

## 17. Built-In Self-Test

A demonstration configuration is pre-loaded in the Quad-SPI flash during manufacturing. When the board is powered on in SPI mode with this demo, it provides basic hardware verification:

| Feature            | Demo Behavior                                                                          |
| ------------------ | -------------------------------------------------------------------------------------- |
| User LEDs          | Illuminate when the corresponding slide switch is on                                   |
| Tri-color LEDs     | BTNL/BTNC/BTNR → red/green/blue; BTND → cycle colors or toggle on/off                  |
| Microphone & Audio | BTNU triggers a 5-second recording played back on audio out; saved in DDR2             |
| VGA Port           | Displays feedback from microphone, temperature, accelerometer, RGB LEDs, and USB mouse |
| USB HID Mouse      | Controls pointer on VGA display (Boot Mouse HID interface required)                    |
| 7-Segment Display  | Shows a moving snake pattern                                                           |

All Nexys 4 DDR boards are **100% tested** during manufacturing. If a board fails within the warranty period, it will be replaced at no cost — contact Digilent for details.

---

_For more information and additional resources, visit [www.digilentinc.com](https://www.digilentinc.com)._
