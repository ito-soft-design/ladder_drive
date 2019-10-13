#
# Copyright (c) 2018 ITO SOFT DESIGN Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

dir = Dir.pwd
$:.unshift dir unless $:.include? dir

require 'active_support'
require 'active_support/core_ext'
require 'erb'


module LadderDrive
module Emulator


class PluginTriggerState
  attr_reader :plc
  attr_reader :config
  attr_reader :device
  attr_reader :value_type
  attr_reader :value

  def initialize plc, config
    @plc = plc
    @config = config
    @device = plc.device_by_name config[:device]
    @value_type = config[:value_type]
  end

  def key
    object_id
  end

  def value
    @value
  end

  def value= value
    if @changed.nil?
      @changed = @value != value
      @raised = @changed && !!value
      @fallen = @changed && !value
      @value = value
    end
  end

  def changed?
    !!@changed
  end

  def raised?
    !!@raised
  end

  def fallen?
    !!@fallen
  end

  def triggered?
    !!@triggered
  end

  def update
    return unless @triggered.nil?

    triggers = config[:triggeres]
    triggers ||= [config[:trigger]]

    @triggered = false

    triggers.each do |trigger|
      case trigger[:type]
      when "changed", "raise", "fall", "raise_and_fall"
        value = device.send(@value_type || :value)
        # update flags
        @changed = @value != value
        case value
        when true, false, nil
          @raised = @changed && !!value
          @fallen = @changed && !value
        else
          @fallen = @changed && value == 0
          @raised = @changed && !@fallen
        end
        @value = value

        # judgement triggered
        case trigger[:type]
        when "raise"
          @triggered = true if @raised
        when "fall"
          @triggered = true if @fallen
        else
          @triggered = true if @changed
        end

      when "interval"
        # TODO:
      else
        @triggered = false
      end
    end
    @triggered
  end

  def reset
    @changed = nil
    @raised = nil
    @fallen = nil
    @triggered = nil
  end

end

end
end
