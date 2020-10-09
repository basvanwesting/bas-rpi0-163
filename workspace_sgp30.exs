
i2c = Circuits.I2C
i2c_retry_count = 2
{:ok, ref} = i2c.open("i2c-1")

address = 0x58

init_air_quality        = 0x2003
measure_air_quality     = 0x2008
get_baseline            = 0x2015
set_baseline            = 0x201e
set_humidity            = 0x2061
measure_test            = 0x2032
get_feature_set_version = 0x202f
measure_raw_signals     = 0x2050

crc_options = %{
  width: 8,
  poly: 0x31,
  init: 0xff,
  refin: false,
  refout: false,
  xorout: 0x00
}

0x92 = CRC.calculate(<<0xBEEF::16>>, crc_options)


# Get feature set

message = <<get_feature_set_version::16>>
reply = i2c.write(ref, address, message, retries: i2c_retry_count)
bytes_to_read = 3
reply = i2c.read(ref, address, bytes_to_read, retries: i2c_retry_count)
{:ok, <<product_type::4, _::4, product_version::8, crc::8>>} = reply


# Measure air quality

message = <<measure_air_quality::16>>
reply = i2c.write(ref, address, message, retries: i2c_retry_count)
bytes_to_read = 6
reply = i2c.read(ref, address, bytes_to_read, retries: i2c_retry_count)
{:ok, <<eco2_ppm::16, eco2_ppm_crc::8, tvoc_ppb::16, tvoc_ppb_crc::8>>} = reply


# self test

message = <<measure_test::16>>
reply = i2c.write(ref, address, message, retries: i2c_retry_count)
bytes_to_read = 3
reply = i2c.read(ref, address, bytes_to_read, retries: i2c_retry_count)
{:ok, <<data::16, crc::8>>} = reply

data == 0xD400
crc == CRC.calculate(<<0xD400::16>>, crc_options)

# loop

message = <<init_air_quality::16>>
reply = i2c.write(ref, address, message, retries: i2c_retry_count)

for i <- 1..1000 do
  message = <<measure_air_quality::16>>
  reply = i2c.write(ref, address, message, retries: i2c_retry_count)

  :timer.sleep(50)

  bytes_to_read = 6
  reply = i2c.read(ref, address, bytes_to_read, retries: i2c_retry_count)
  {:ok, <<eco2_ppm::16, eco2_ppm_crc::8, tvoc_ppb::16, tvoc_ppb_crc::8>>} = reply

  IO.puts "eCO2: #{eco2_ppm} ppm, TVOC: #{tvoc_ppb} ppb"

  :timer.sleep(950)
end
