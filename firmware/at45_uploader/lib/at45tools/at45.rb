require 'at45tools/constants.rb'

class AT45
  def initialize(buspirate, pagecount, pagesize) 
    @bp = buspirate;
    @pagesize=pagesize
    @pagecount=pagecount
    configure_buspirate
  end

  def get_version
    retval = nil
    ensure_proper do
      @bp.spi_cs_block(true) do
        retval = @bp.spi_write_then_read(AT45::CMD::GET_VERSION, 4, false)
      end
    end
    return retval;
  end

  def get_status
    retval = 0x00;
    ensure_proper do
      @bp.spi_cs_block(true) do
        #retval = @bp.spi_write_then_read(AT45::CMD::GET_STATUS, 1, true) 
        retval = @bp.spi_bulk_write_read(AT45::CMD::GET_STATUS) 
        retval = @bp.spi_bulk_write_read([0xFF]) 
      end
    end
    return retval;
  end

  def ready?
    foo = get_status
    #pp "Status: %08b" % foo
    return check_bitmask_set?(foo[0], AT45::STATUS::READY)
  end

  def wait_for_ready
    while (! ready?) do
      print(".")
      sleep(1)
    end
  end

  def chip_erase_wait
    retval = []
    ensure_proper do
      @bp.spi_cs_block(true) do
        #pp "Sending %02x%02x%02x%02x" % AT45::CMD::CHIP_ERASE
        #retval = @bp.spi_bulk_write_read(AT45::CMD::CHIP_ERASE)
        retval = @bp.spi_bulk_write_read(AT45::CMD::CHIP_ERASE);
        retval = @bp.spi_bulk_write_read([0x00,0x00,0x00,0x00]);
        #pp "returned %02x%02x%02x%02x" % retval;
      end
    end
    sleep(1)
    wait_for_ready;
  end

  def upload_page(page, data, opts = {}) 
    raise ArgumentError, 'page out of range' unless 0 <= page && page < @pagecount;
    $at45.write_to_buf1(data);
    # erase page - otherwise, the memory is not fully written.
    if (! opts[:erase] == false) 
      $at45.erase_page(page) 
      $at45.wait_for_ready();
    end 
    $at45.buf1_to_mm(page);
    $at45.wait_for_ready();
    if (opts[:verify] == true)
      $at45.mm_to_buf1(page);
      $at45.wait_for_ready();
      readbuf = $at45.read_from_buf1();
      if (readbuf != data) 
        raise RuntimeError, "Page #{page} not written correctly."
      else
        return readbuf
      end
    else
      return data
    end
    
  end

  def erase_page(page)
    raise ArgumentError, 'page out of range' unless 0 <= page && page < @pagecount;
    ensure_proper do
      @bp.spi_cs_block(true) do
        # Send cmd byte
        retval = @bp.spi_bulk_write_read(AT45::CMD::PAGE_ERASE) 
        # Send 3-byte address 
        pageaddr=[0x00] << (((page << 1) & 0x0f00) >> 8) << ((page << 1) & 0x00fe) 
        retval = @bp.spi_bulk_write_read(pageaddr) 
      end
    end
  end

  def buf1_to_mm(page)
    raise ArgumentError, 'page out of range' unless 0 <= page && page < @pagecount;
    ensure_proper do
      @bp.spi_cs_block(true) do
        # Send cmd byte
        retval = @bp.spi_bulk_write_read(AT45::CMD::BUFFER1_TO_MM) 
        # Send 3-byte address 
        pageaddr=[0x00] << (((page << 1) & 0x0f00) >> 8) << ((page << 1) & 0x00fe) 
        retval = @bp.spi_bulk_write_read(pageaddr) 
      end
    end
  end

  def mm_to_buf1(page)
    raise ArgumentError, 'page out of range' unless 0 <= page && page < @pagecount;
    ensure_proper do
      @bp.spi_cs_block(true) do
        # Send cmd byte
        retval = @bp.spi_bulk_write_read(AT45::CMD::MM_TO_BUFFER1) 
        # Send 3-byte address 
        pageaddr=[0x00] << (((page << 1) & 0x0f00) >> 8) << ((page << 1) & 0x00fe) 
        retval = @bp.spi_bulk_write_read(pageaddr) 
      end
    end
  end

  def write_to_buf1(data)
    retval = 0x00;
    raise ArgumentError, 'data is not an array' unless data.is_a? Array
    raise ArgumentError, 'data size invalid' unless 0 <= data.length && data.length <= @pagesize;
    ensure_proper do
      @bp.spi_cs_block(true) do
        # Send cmd byte
        @bp.spi_bulk_write_read(AT45::CMD::BUFFER1_WRITE) 
        # Send 3-byte address - 15 reserved bits, 9 address bits
        @bp.spi_bulk_write_read([0x00,0x00,0x00]) 
        retval = @bp.spi_bulk_write_read(data) 
      end
    end
  end

  def read_from_buf1()
    retval = [];
    ensure_proper do
      @bp.spi_cs_block(true) do
        # Send cmd byte
        retval = @bp.spi_bulk_write_read(AT45::CMD::BUFFER1_READ) 
        # Send 3-byte address - 15 reserved bits, 9 address bits
        retval = @bp.spi_bulk_write_read([0x00,0x00,0x00]) 
        # Send 1 bytes to give the AT45 time to initialize
        retval = @bp.spi_bulk_write_read([0x00]) 
        # clock dummy data in to read buffer.
        retval = @bp.spi_bulk_write_read([].fill(0x00, 0..@pagesize-1));
      end
    end
    return retval;
  end

  private
  def check_bitmask_set? (value, mask)
    return ((value & mask) == mask)
  end

  def configure_buspirate
    ensure_proper do 
      @bp.switch_mode(BusPirate::Mode::SPI);
      @bp.reset_console;

      print "entering bitbang mode..\t\t"
      if @bp.enter_bitbang
        puts "done"
      else
        puts "failed"
        exit
      end

      print "entering binary SPI mode...\t"
      if @bp.switch_mode(BusPirate::Mode::SPI)
        puts "done"
      else
        puts "failed"
        exit
      end

      print "setting speed...\t\t"
      if @bp.spi_set_speed(BusPirate::SPI::SPEED_8MHZ)
        puts "done"
      else
        puts "failed"
        exit
      end

      print "setting configuration...\t"
      if @bp.spi_set_config(BusPirate::SPI::PIN_OUTPUT_33V, 
                            BusPirate::SPI::CLOCK_IDLE_LOW, 
                            #BusPirate::SPI::CLOCK_EDGE_IDLE_TO_ACTIVE, 
                            BusPirate::SPI::CLOCK_EDGE_ACTIVE_TO_IDLE, 
                            BusPirate::SPI::SAMPLE_TIME_MIDDLE)
                            puts "done"
      else
        puts "failed"
        exit
      end

      print "configuring peripherals...\t"
      if (@bp.config_peripherals(true, false, true, true) &&
          @bp.configure_pins(BusPirate::PinMode::INPUT, BusPirate::PinMode::OUTPUT,
                             BusPirate::PinMode::OUTPUT,BusPirate::PinMode::INPUT,
                             BusPirate::PinMode::OUTPUT))

        puts "done"
      else
        puts "failed"
        exit
      end

      print "setting CS low...\t\t"
      if @bp.spi_set_cs(true)
        puts "done"
      else
        puts "failed"
        exit
      end
    end
  end

  # Run the provided block. If any exception occurs, properly close the
  # bus pirate device.
  def ensure_proper
    begin
      yield
    rescue => e
      puts "Error: #{e}"
    end
  end

end
