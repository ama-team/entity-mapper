# frozen_string_literal: true

require_relative '../../../lib/mapper'
require_relative '../../../lib/mapper/dsl'
require_relative '../../../lib/mapper/type/any'

klass = ::AMA::Entity::Mapper
any_type = ::AMA::Entity::Mapper::Type::Any::INSTANCE

factory = lambda do |name, &block|
  Class.new do
    include ::AMA::Entity::Mapper::DSL
    instance_eval(&block) if block
    define_singleton_method :to_s do
      name
    end
  end
end

describe klass do
  before(:each) do
    klass.handler = klass.new
  end

  let(:public_key) do
    factory.call('PublicKey') do
      attribute :id, Symbol
      attribute :owner, Symbol
      attribute :content, String, sensitive: true
      attribute :digest, Integer, NilClass, nullable: true
      attribute :type, Symbol, values: %i[ssh-rsa ssh-dss], default: :'ssh-rsa'
      attribute :comment, Symbol, NilClass

      define_method(:content=) do |content|
        @content = content
        @digest = content.size
      end

      denormalizer_block do |input, type, context, &block|
        input = { content: input } if input.is_a?(String)
        %i[id owner].each_with_index do |key, index|
          candidate = context.path.segments[(-1 - index)]
          input[key] = candidate.name if !input[key] && candidate
        end
        # TODO: when default functionality will be done, remove that line
        input[:type] = :'ssh-rsa' unless input[:type] || input['type']
        block.call(input, type, context)
      end
    end
  end

  let(:private_key_host) do
    factory.call('PrivateKey.Host') do
      attribute :id, Symbol
      attribute :options, [Hash, K: Symbol, V: [String, Symbol, Integer]]

      denormalizer_block do |input, type, context, &block|
        input = {} if input.nil?
        input = { User: input } if input.is_a?(String) || input.is_a?(Symbol)
        data = {}
        data[:id] = input[:id] || input['id'] || context.path.current.name
        data[:options] = input[:options] || input['options'] || {}
        input.each do |key, value|
          next if %i[id options].include?(key.to_sym)
          data[:options][key] = value
        end
        block.call(data, type, context)
      end
    end
  end

  let(:private_key) do
    private_key_host = self.private_key_host
    factory.call('PrivateKey') do
      attribute :id, Symbol
      attribute :owner, Symbol
      attribute :content, String, sensitive: true
      attribute :digest, Integer, NilClass, nullable: true
      attribute :hosts, [Hash, K: Symbol, V: private_key_host]

      denormalizer_block do |input, type, context, &block|
        input = { content: input } if input.is_a?(String)
        %i[id owner].each_with_index do |key, index|
          candidate = context.path.segments[(-1 - index)]
          input[key] = candidate.name if !input[key] && candidate
        end
        input[:hosts] = {} unless input[:hosts] || input['hosts']
        block.call(input, type, context)
      end

      define_method(:content=) do |content|
        @content = content
        @digest = content.size
      end
    end
  end

  let(:privilege) do
    factory.call('Privilege') do
      attribute :id, Symbol
      attribute :options, [Hash, K: Symbol, V: any_type]
      denormalizer_block do |data, type, context, &block|
        data = {} if data.nil?
        target = { options: data[:options] || {} }
        target[:id] = data[:id] || context.path.current.name
        data.each do |key, value|
          next if %i[id options].include?(key)
          target[:options][key] = value
        end
        block.call(target, type, context)
      end
    end
  end

  let(:account) do
    privilege = self.privilege
    public_key = self.public_key
    private_key = self.private_key
    factory.call('Account') do
      attribute :id, Symbol
      attribute :policy, Symbol, values: %i[none edit manage]
      attribute :privileges, [Hash, K: Symbol, V: privilege]
      attribute :public_keys, [Hash, K: Symbol, V: [Hash, K: Symbol, V: public_key]]
      attribute :private_keys, [Hash, K: Symbol, V: private_key]
      denormalizer_block do |data, type, context, &block|
        data[:id] = context.path.current.name unless data[:id]
        block.call(data, type, context)
      end
    end
  end

  describe '> account mapping' do
    it 'solves case #1' do |test_case|
      input = {
        'bill' => {
          'policy' => 'manage',
          'privileges' => {
            'sudo' => nil,
            'mount' => {
              'disks' => ['/dev/sda']
            }
          },
          'private_keys' => {
            'id_rsa' => 'private key',
            'id_bsa' => {
              'content' => 'private key',
              'hosts' => {
                'private.server' => nil,
                'github.com' => 'git',
                'secure.server' => {
                  Port: 22,
                  User: 'engineer',
                  Host: 'secure.company.com'
                }
              }
            }
          },
          'public_keys' => {
            'bill' => {
              'id_rsa' => 'public key',
              'id_bsa' => {
                'content' => 'public key',
                'type' => 'ssh-dss'
              }
            }
          }
        }
      }

      mapped = nil
      test_case.step 'mapping' do
        mapped = klass.map(input, [Hash, K: Symbol, V: account])
      end

      test_case.step 'external hash validation' do
        expect(mapped).to be_a(Hash)
        expect(mapped).to include(:bill)
      end

      bill = nil
      test_case.step 'account validation' do
        bill = mapped[:bill]
        expect(bill).to be_a(account)
        expect(bill.policy).to eq(:manage)
        expect(bill.privileges).to include(:sudo, :mount)
        expect(bill)
      end

      test_case.step 'sudo privilege validation' do
        expect(bill.privileges).to include(:sudo)
        sudo = bill.privileges[:sudo]
        expect(sudo).to be_a(privilege)
        expect(sudo.id).to eq(:sudo)
        expect(sudo.options).to eq({})
      end
      test_case.step 'mount privilege valudation' do
        expect(bill.privileges).to include(:mount)
        mount = bill.privileges[:mount]
        expect(mount).to be_a(privilege)
        expect(mount.id).to eq(:mount)
        expect(mount.options).to eq(disks: ['/dev/sda'])
      end

      keyring = {}
      test_case.step 'public keyring validation' do
        expect(bill.public_keys).to include(:bill)
        keyring = bill.public_keys[:bill]
      end

      test_case.step 'id_rsa public key validation' do
        expect(keyring).to include(:id_rsa)
        key = keyring[:id_rsa]
        expect(key).to be_a(public_key)
        expect(key.id).to eq(:id_rsa)
        expect(key.type).to eq(:'ssh-rsa')
        expect(key.content).to eq('public key')
        expect(key.digest).to eq(key.content.size)
      end

      test_case.step 'id_bsa public key validation' do
        expect(keyring).to include(:id_bsa)
        key = keyring[:id_bsa]
        expect(key).to be_a(public_key)
        expect(key.id).to eq(:id_bsa)
        expect(key.type).to eq(:'ssh-dss')
        expect(key.content).to eq('public key')
        expect(key.digest).to eq(key.content.size)
      end

      test_case.step 'id_rsa private key validation' do
        expect(bill.private_keys).to include(:id_rsa)
        key = bill.private_keys[:id_rsa]
        expect(key).to be_a(private_key)
        expect(key.id).to eq(:id_rsa)
        expect(key.content).to eq('private key')
        expect(key.digest).to eq(key.content.size)
        # TODO: default value check for hosts
      end

      test_case.step 'id_bsa private key validation' do
        expect(bill.private_keys).to include(:id_bsa)
        key = bill.private_keys[:id_bsa]
        expect(key).to be_a(private_key)
        expect(key.id).to eq(:id_bsa)
        expect(key.content).to eq('private key')
        expect(key.digest).to eq(key.content.size)
        hosts = %i[private.server github.com secure.server]
        expect(key.hosts).to include(*hosts)
        hosts.each do |hostname|
          host = key.hosts[hostname]
          expect(host).to be_a(private_key_host)
          expect(host.id).to eq(hostname)
          expect(host.options).to be_a(Hash)
        end
        expect(key.hosts[:'github.com'].options[:User]).to eq('git')
        expectation = {
          Port: 22,
          User: 'engineer',
          Host: 'secure.company.com'
        }
        expect(key.hosts[:'secure.server'].options).to eq(expectation)
      end
    end
  end
end
