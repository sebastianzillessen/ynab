#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'csv'
require_relative 'qif'
require_relative 'qif_export'
require 'pry'

require 'rubygems'
require 'exchange'


class DebitLloyds < QifExport
  def self.credential_selector
    "lloyds"
  end

  def from_web username, password, account, attrs={}
    @csv = {}

    unless attrs[:memorizable_information]
      $stderr.print "Memorizable Information: "; attrs[:memorizable_information] = gets.strip
    end

    args = "-u #{username} -p #{password} -m #{attrs[:memorizable_information]} -a #{(Date.today - 30).strftime("%Y/%m/%d")}--#{Date.today.strftime("%Y/%m/%d")}"
    output = `python #{File.expand_path File.dirname(__FILE__)}/download.py #{args}`
    @files = JSON.parse(output.split("\n").last.gsub("'", "\"")).flatten

  end

  def sanitise

  end

  def memo transaction
    "[#{transaction.amount}GBP] #{transaction.memo}"
  end

  def amount transaction
    transaction.amount.in(:gbp).to(:eur, :at => transaction.date.to_time).to_f
  end

  def parse_file(file)
    unless (file.nil?)
      @files = [file]
    end
    if @csv.nil?
      @csv={}
    end
    @files.each_with_index do |f, i|
      qif = Qif::Reader.new(open(f))
      Qif::Writer.open(file.gsub(".qif", "eur.qif"), type='Bank', format="dd/mm/yyyy") do |writer|
        qif.each do |transaction|
          writer << Qif::Transaction.new(
            :date => transaction.date,
            :amount => amount(transaction),
            :payee => transaction.payee,
            :memo => memo(transaction)
          )
        end
      end
    end
  end

  def parse()
    @files.each do |f|
      qif = Qif::Reader.new(open(f))
      @csv["lloyds_#{f.split("_").first}"] =
        qif.map do |transaction|
          {
            :date => transaction.date,
            :amount => amount(transaction),
            :payee => transaction.payee,
            :memo => memo(transaction)
          }
        end
      File.delete(f)
    end
    @csv
  end

  private
end

Qif.print_many(CreditCardDKB.transactions!) if __FILE__ == $0