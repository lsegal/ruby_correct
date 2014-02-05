require 'yard'
require_relative '../lib/ruby_correct/yard_ext'

def calculate_weights(result)
  total = 0
  weights = {'local' => 1, 'param' => 1, 'return' => 1, 'ensures' => 3, 'requires' => 2, 'modifies' => 2, 'invariant' => 4, 'other' => 1}
  result.each do |k, v|
    next if k == 'total'
    total += weights[k] * v
  end
  total
end

def get_annots(file)
  types = %w(local param return ensures requires invariant)
  YARD::Registry.clear
  YARD.parse(file)
  results = Hash.new { 0 }
  YARD::Registry.all.each do |obj|
    obj.tags.each do |tag|
      next if tag.tag_name == 'ast'
      next if tag.tag_name == 'raise'
      results['total'] += 1
      results[types.include?(tag.tag_name) ? tag.tag_name : 'other'] += 1
    end
  end
  results
end

Dir['examples/ruby_esc/*.rb'].each do |file|
  base = File.basename(file)
  other = File.join('examples/ruby_case_gen/esc/', base)
  next unless File.file?(other)
  annots1 = get_annots(file)
  annots2 = get_annots(other)
  l, le = '&', '\\\\'
  w1, w2 = calculate_weights(annots1), calculate_weights(annots2)
  args = [base.gsub('_', '\_'), l, annots1['total'].to_s, l, annots2['total'].to_s, l,
    w1.to_s, l, w2.to_s, l, '-' + (w1-w2).to_s, le]
  puts "%-20s %s %6s %s %6s %s %6s %s %6s %s %6s %s" % args
end