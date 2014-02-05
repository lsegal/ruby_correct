class Container2
  # @return [String]
  def data()
    @data
  end

  # @param [String] v
  # @return [String]
  def data=(v)
    @data = v
  end

  # @param [Container2] el
  # @return [void]
  def swap(el)
    @data = "Hello" if @data == nil
    tmp = @data
    self.data = el.data
    el.data = tmp
  end
end